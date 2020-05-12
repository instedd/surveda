defmodule Ask.QuestionnaireSimulation do
  defstruct [:respondent, :questionnaire, messages: [], submissions: []]
end

defmodule Ask.QuestionnaireSimulationStep do
  alias Ask.QuestionnaireSimulation
  alias Ask.Simulation.Status
  alias __MODULE__

  defstruct [:respondent_id, :simulation_status, :disposition, :current_step, messages_history: [], submissions: []]

  def build(%QuestionnaireSimulation{respondent: respondent, messages: all_messages, submissions: submissions}, current_step, status) do
    %QuestionnaireSimulationStep{respondent_id: respondent.id, disposition: respondent.disposition, messages_history: all_messages, simulation_status: status, submissions: submissions, current_step: current_step}
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
  alias Ask.Simulation.{Status, ATMessage, AOMessage, SubmittedStep, Response}
  alias Ask.Runtime.{Session, Flow, QuestionnaireSimulatorStore}

  @sms_mode "sms"

  def start_simulation(project, questionnaire, mode \\ @sms_mode) do
    if valid_questionnaire?(questionnaire, mode) do
      start(project, questionnaire, mode)
    else
      Response.invalid_simulation
    end
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
      respondent_id
      |> QuestionnaireSimulationStep.expired
      |> Response.success
    end
  end

  defp valid_questionnaire?(quiz, mode), do: quiz.modes |> Enum.member?(mode)

  defp start(%Project{} = project, %Questionnaire{} = questionnaire, @sms_mode) do
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
      sanitized_phone_number: "",
      responses: []
    }

    # Simulating what Broker does when starting a respondent: Session.start and then Survey.handle_session_step
    session_started = Session.start(questionnaire, new_respondent, %Ask.Runtime.SimulatorChannel{}, @sms_mode, Ask.Schedule.always(), [], nil, nil, [], nil, false, false)
    {:reply, reply, respondent} = Runtime.Survey.handle_session_step(session_started, SystemTime.time.now, false)

    # Simulating Nuntium confirmation on message delivery
    %{respondent: respondent} = Runtime.Survey.delivery_confirm(sync_respondent(respondent), "", @sms_mode, false)

    messages = AOMessage.create_all(reply)
    submitted_steps = SubmittedStep.build_from(reply, questionnaire)
    current_step = current_step(reply)

    QuestionnaireSimulatorStore.add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{questionnaire: questionnaire, respondent: sync_respondent(respondent), messages: messages, submissions: submitted_steps})
    |> QuestionnaireSimulationStep.build(current_step, Status.active)
    |> Response.success
  end

  defp start(_project, _questionnaire, _mode) do
    Response.invalid_simulation
  end

  # Must update the respondent.session's respondent since if not will be outdated from respondent
  # This is necessary since some flows:
  #  - start using the respondent,
  #  - then use the respondent.session
  #  - and after that use the session.respondent
  #
  # If not synced, respondent data would be loss during simulation and the simulation could behave inaccurately
  defp sync_respondent(respondent) do
    synced_session = if respondent.session, do: %{respondent.session | respondent: respondent}, else: respondent.session
    %{respondent | session: synced_session}
  end

  defp handle_app_reply(simulation, respondent, reply, status) do
    messages = simulation.messages ++ AOMessage.create_all(reply)
    submitted_steps = simulation.submissions ++ SubmittedStep.build_from(reply, simulation.questionnaire)
    current_step = current_step(reply)

    QuestionnaireSimulatorStore.add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{simulation | respondent: sync_respondent(respondent), messages: messages, submissions: submitted_steps})
    |> QuestionnaireSimulationStep.build(current_step, status)
    |> Response.success
  end

  defp current_step(reply) do
    case Ask.Runtime.Reply.steps(reply) |> List.last do
      nil -> nil
      step -> step.id
    end
  end
end

defmodule Ask.Simulation.SubmittedStep do
  alias Ask.Runtime.Reply
  alias Ask.Questionnaire

  def build_from(reply, questionnaire) do
    responses = Reply.stores(reply)
                |> Enum.map(fn {step_name, value} ->
                  # find function is used since there is a restriction that two steps cannot have the same store variable name
                  %{"title" => title, "id" => id} = questionnaire
                                                    |> Questionnaire.all_steps
                                                    |> Enum.find(fn step -> step["store"] == step_name end)
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
  def create_all(nil), do: []
  def create_all(reply) do
    Enum.flat_map Ask.Runtime.Reply.steps(reply), fn step ->
      step.prompts |> Enum.with_index |> Enum.map(fn {prompt, index} ->
        %{
          body: prompt,
          title: Ask.Runtime.ReplyStep.title_with_index(step, index + 1),
          id: step.id,
          type: "ao"
        }
      end)
    end
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

defmodule Ask.Simulation.Response do
  def success(simulation_step), do: {:ok, simulation_step}
  def invalid_simulation, do: {:error, :invalid_simulation}
end