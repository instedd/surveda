defmodule Ask.QuestionnaireSimulation do
  defstruct [:respondent, :questionnaire, messages: [], submissions: []]
end

defmodule Ask.QuestionnaireSimulationStep do
  alias Ask.QuestionnaireSimulation
  alias Ask.Simulation.Status
  alias __MODULE__

  defstruct [:respondent_id, :simulation_status, :disposition, messages_history: [], submissions: []]

  def build(%QuestionnaireSimulation{respondent: respondent, messages: all_messages, submissions: submissions}, status) do
    %QuestionnaireSimulationStep{respondent_id: respondent.id, disposition: respondent.disposition, messages_history: all_messages, simulation_status: status, submissions: submissions}
  end

  def expired(respondent_id) do
    %QuestionnaireSimulationStep{respondent_id: respondent_id, simulation_status: Status.expired}
  end
end

defmodule Ask.Runtime.SimulatorChannel do
  defstruct patterns: []
end

defmodule Ask.Runtime.QuestionnaireSimulator do
  alias Ask.{Survey, Respondent, Questionnaire, Project, SystemTime, Runtime, QuestionnaireSimulationStep}
  alias Ask.Simulation.{Status, ATMessage, AOMessage, SubmittedStep}
  alias Ask.Runtime.{Session, Flow, QuestionnaireSimulatorStore}

  @sms_mode "sms"

  def start_simulation(project, questionnaire, mode \\ @sms_mode)

  def start_simulation(%Project{} = project, %Questionnaire{} = questionnaire, @sms_mode) do
    survey = %Survey{
      simulation: true,
      project_id: project.id,
      name: questionnaire.name,
      mode: [[@sms_mode]],
      state: "running",
      cutoff: 1,
      schedule: Ask.Schedule.always(),
      started_at: Timex.now
    }

    new_respondent = %Respondent{
      id: Ecto.UUID.generate(),
      survey_id: survey.id,
      survey: survey,
      questionnaire_id: questionnaire.id,
      mode: [@sms_mode],
      disposition: "queued",
      phone_number: "",
      canonical_phone_number: "",
      sanitized_phone_number: ""
    }

    # Simulating what Broker does when starting a respondent: Session.start and then Survey.handle_session_step
    session_started = Session.start(questionnaire, new_respondent, %Ask.Runtime.SimulatorChannel{}, @sms_mode, Ask.Schedule.always(), [], nil, nil, [], nil, false, false)
    {:reply, reply, respondent} = Runtime.Survey.handle_session_step(session_started, SystemTime.time.now, false)

    # Must nest respondent in respondent.session since this is the one updated
    # If not respondent data would be loss for simulation
    respondent_for_confirmation = %{respondent | session: %{respondent.session | respondent: respondent}}

    # Simulating Nuntium confirmation on message delivery
    %{respondent: respondent} = Runtime.Survey.delivery_confirm(respondent_for_confirmation, "", @sms_mode, false)

    messages = reply |> reply_to_messages |> AOMessage.create_all
    submitted_steps = SubmittedStep.build_from(reply, questionnaire)

    QuestionnaireSimulatorStore.add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{questionnaire: questionnaire, respondent: respondent, messages: messages, submissions: submitted_steps})
    |> QuestionnaireSimulationStep.build(Status.active)
  end

  def start_simulation(_project, _questionnaire, _mode) do
    :not_implemented
  end

  def process_respondent_response(respondent_id, response) do
    simulation = QuestionnaireSimulatorStore.get_respondent_simulation(respondent_id)
    if(simulation) do
      %{respondent: respondent, messages: messages} = simulation
      updated_messages = messages ++ [ATMessage.new(response)]
      simulation = QuestionnaireSimulatorStore.add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{simulation | messages: updated_messages})
      reply = Flow.Message.reply(response)

      case Runtime.Survey.sync_step(respondent, reply, @sms_mode, SystemTime.time.now, false) do
        {:reply, reply, respondent} ->
          handle_app_reply(simulation, respondent, reply, Status.active)
        {:end, {:reply, reply}, respondent} ->
          handle_app_reply(simulation, respondent, reply, Status.ended)
        {:end, respondent} ->
          handle_app_reply(simulation, respondent, nil, Status.ended)
      end
    else
      QuestionnaireSimulationStep.expired(respondent_id)
    end
  end

  def handle_app_reply(simulation, respondent, reply, status) do
    reply_messages = reply_to_messages(reply) |> AOMessage.create_all
    messages = simulation.messages ++ reply_messages

    submitted_steps = simulation.submissions ++ SubmittedStep.build_from(reply, simulation.questionnaire)

    QuestionnaireSimulatorStore.add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{simulation | respondent: respondent, messages: messages, submissions: submitted_steps})
    |> QuestionnaireSimulationStep.build(status)
  end

  defp reply_to_messages(nil), do: []
  defp reply_to_messages(reply) do
    Enum.flat_map Ask.Runtime.Reply.steps(reply), fn step ->
      step.prompts |> Enum.with_index |> Enum.map(fn {prompt, index} ->
        %{
          body: prompt,
          title: Ask.Runtime.ReplyStep.title_with_index(step, index + 1),
          id: step.id
        }
      end)
    end
  end
end

defmodule Ask.Simulation.SubmittedStep do
  alias Ask.Runtime.Reply
  alias Ask.Questionnaire

  def build_from(reply, questionnaire) do
    responses = Reply.stores(reply)
                |> Enum.map(fn {step_name, value} ->
                  referred_step = questionnaire |> Questionnaire.all_steps |> Enum.filter(fn step -> step["store"] == step_name end)
                  [id] = referred_step |> Enum.map(fn step -> step["id"] end)
                  [title] = referred_step |> Enum.map(fn step -> step["title"] end)
                  %{step: title, response: value, id: id}
    end)


    explanation_steps = Reply.steps(reply)
                        |> Enum.filter(fn step -> step.type == "explanation" end)
                        |> Enum.filter(fn step -> step.title not in ["Thank you", "Error"] end)
                        |> Enum.map(fn step -> %{step: step.title, id: step.id} end)
    responses ++ explanation_steps
  end
end

defmodule Ask.Simulation.AOMessage do
  def create_all(messages) do
    messages |> Enum.map(fn msg -> msg |> Map.put(:type, "ao") end)
  end
end

defmodule Ask.Simulation.ATMessage do
  def new(response) do
    %{body: response, type: "at"}
  end
end

defmodule Ask.Simulation.Status do
  def active, do: "active"
  def ended, do: "ended"
  def expired, do: "expired"
end