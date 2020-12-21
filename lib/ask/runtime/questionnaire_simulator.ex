defmodule Ask.QuestionnaireSimulation do
  defstruct [:respondent, :questionnaire, :section_order, :last_simulation_response, messages: [], submissions: []]
end

defmodule Ask.QuestionnaireSimulationStep do
  alias Ask.QuestionnaireSimulation
  alias Ask.Simulation.Status
  alias __MODULE__

  defstruct [:respondent_id, :simulation_status, :disposition, :current_step, :reply, :questionnaire, messages_history: [], submissions: []]

  def start_build(simulation, current_step, status, reply), do: build(simulation, current_step, status, true, reply)
  def sync_build(simulation, current_step, status, reply), do: build(simulation, current_step, status, false, reply)

  def expired(respondent_id) do
    %QuestionnaireSimulationStep{respondent_id: respondent_id, simulation_status: Status.expired}
  end

  defp build(%QuestionnaireSimulation{respondent: respondent, messages: all_messages, submissions: submissions, questionnaire: quiz, section_order: section_order}, current_step, status, with_quiz, reply) do
    step = %QuestionnaireSimulationStep{
      respondent_id: respondent.id,
      simulation_status: status,
      disposition: respondent.disposition,
      current_step: current_step,
      messages_history: all_messages,
      submissions: submissions,
      # The mobileweb simulation controller needs the reply to render properly
      reply: reply
    }
    if with_quiz, do: %{step | questionnaire: sort_quiz_sections(quiz, section_order)}, else: step
  end

  defp sort_quiz_sections(quiz, nil), do: quiz
  defp sort_quiz_sections(quiz, section_order) do
    sorted_steps = section_order |> Enum.reduce([], fn index, acc -> acc ++ [quiz.steps |> Enum.at(index)] end)
    %{quiz | steps: sorted_steps}
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
  @mobileweb_mode "mobileweb"

  def start_simulation(project, questionnaire, mode \\ @sms_mode) do
    if valid_questionnaire?(questionnaire, mode) do
      start(project, questionnaire, mode)
    else
      Response.invalid_simulation
    end
  end

  # The mobileweb simulator needs the last response to update the screen asynchronously
  def get_last_simulation_response(respondent_id) do
    simulation = QuestionnaireSimulatorStore.get_respondent_simulation(respondent_id)
    if (simulation) do
      %{last_simulation_response: last_simulation_response} = simulation
      last_simulation_response
    else
      respondent_id
      |> QuestionnaireSimulationStep.expired
      |> Response.success
    end
  end

  def process_respondent_response(respondent_id, response, mode \\ @sms_mode) do
    simulation = QuestionnaireSimulatorStore.get_respondent_simulation(respondent_id)
    if (simulation) do
      {:ok, %{simulation: simulation, simulation_response: simulation_response}} = sync_simulation(simulation, response, mode)
      QuestionnaireSimulatorStore.add_respondent_simulation(respondent_id, %Ask.QuestionnaireSimulation{simulation | last_simulation_response: simulation_response})
      simulation_response
    else
      respondent_id
      |> QuestionnaireSimulationStep.expired
      |> Response.success
    end
  end

  defp sync_simulation(simulation, response, mode) do
    %{respondent: respondent, messages: messages} = simulation
    updated_messages = messages ++ [ATMessage.new(response)]
    simulation = %{simulation | messages: updated_messages}
    # :answer is the response used by MobileSurveyController.get_step to call Survey.sync_step
    # The mobile survey simulation controller emulates this behaviour
    reply = if response == :answer, do: :answer, else: Flow.Message.reply(response)

    case Runtime.Survey.sync_step(respondent, reply, mode, SystemTime.time.now, false) do
      {:reply, reply, respondent} ->
        handle_app_reply(simulation, respondent, reply, Status.active)
      {:end, {:reply, reply}, respondent} ->
        handle_app_reply(simulation, respondent, reply, Status.ended)
      {:end, respondent} ->
        handle_app_reply(simulation, respondent, nil, Status.ended)
    end
  end

  defp valid_questionnaire?(quiz, mode), do: quiz.modes |> Enum.member?(mode)

  defp start(%Project{} = project, %Questionnaire{} = questionnaire, mode) when mode in [@sms_mode, @mobileweb_mode] do
    survey = %Survey{
      simulation: true,
      project_id: project.id,
      name: questionnaire.name,
      mode: [[mode]],
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
      mode: [mode],
      disposition: "queued",
      phone_number: "",
      canonical_phone_number: "",
      sanitized_phone_number: "",
      responses: []
    }

    # Simulating what Broker does when starting a respondent: Session.start and then Survey.handle_session_step
    session_started = Session.start(questionnaire, new_respondent, %Ask.Runtime.SimulatorChannel{}, mode, Ask.Schedule.always(), [], nil, nil, [], nil, false, false)
    {:reply, reply, respondent} = Runtime.Survey.handle_session_step(session_started, SystemTime.time.now, false)
    section_order = respondent.session.flow.section_order

    # Simulating Nuntium confirmation on message delivery
    %{respondent: respondent} = Runtime.Survey.delivery_confirm(sync_respondent(respondent), "", mode, false)

    messages = AOMessage.create_all(reply)
    submitted_steps = SubmittedStep.new_explanations(reply)
    current_step = current_step(reply)

    simulation = %Ask.QuestionnaireSimulation{questionnaire: questionnaire, respondent: sync_respondent(respondent), messages: messages, submissions: submitted_steps, section_order: section_order}
    response =
      simulation
      |> QuestionnaireSimulationStep.start_build(current_step, Status.active, reply)
      |> Response.success

    QuestionnaireSimulatorStore.add_respondent_simulation(respondent.id, %{simulation | last_simulation_response: response})
    response
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
    submitted_steps = simulation.submissions ++ SubmittedStep.build_from_responses(respondent, simulation) ++ SubmittedStep.new_explanations(reply)
    current_step = current_step(reply)

    simulation = %{simulation | respondent: sync_respondent(respondent), messages: messages, submissions: submitted_steps}
    simulation_response =
      simulation
      |> QuestionnaireSimulationStep.sync_build(current_step, status, reply)
      |> Response.success
    {:ok, %{simulation: simulation, simulation_response: simulation_response}}
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

  # Extract new responses from respondent
  def build_from_responses(respondent, %{submissions: submissions, questionnaire: quiz}) do
    present_submissions = submissions |> Enum.map(fn submitted_step -> submitted_step.step_name end)
    new_responses = respondent.responses |> Enum.filter(fn response -> not (present_submissions |> Enum.member?(response.field_name)) end)

    new_responses
    |> Enum.map(fn %{field_name: step_name, value: value} ->
      # find function is used since there is a restriction that two steps cannot have the same store variable name
      %{"id" => id} = quiz |> Questionnaire.all_steps |> Enum.find(fn step -> step["store"] == step_name end)
      %{response: value, step_id: id, step_name: step_name}
    end)

  end

  # Explanation submitted-steps must be extracted from reply since aren't stored as responses
  def new_explanations(reply) do
    Reply.steps(reply)
    |> Enum.filter(fn step -> step.type == "explanation" end)
    |> Enum.filter(fn step -> step.title not in ["Thank you", "Error"] end)
    |> Enum.map(fn step -> %{step_id: step.id, step_name: step.title} end)
  end

end

defmodule Ask.Simulation.AOMessage do
  def create_all(nil), do: []
  def create_all(reply) do
    Enum.map Ask.Runtime.Reply.prompts(reply), fn prompt ->
        %{body: prompt, type: "ao"}
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
