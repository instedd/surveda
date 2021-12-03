defmodule Ask.QuestionnaireMobileWebSimulation do
  defstruct [:respondent, :questionnaire, :section_order, :last_simulation_response, submissions: []]
end

defmodule Ask.QuestionnaireSmsSimulation do
  defstruct [:respondent, :questionnaire, :section_order, messages: [], submissions: []]
end

defmodule Ask.QuestionnaireIvrSimulation do
  defstruct [:respondent, :questionnaire, :section_order, messages: [], submissions: []]
end

defmodule Ask.QuestionnaireSimulationStep do
  alias Ask.Simulation.Status
  alias __MODULE__

  defstruct [:respondent_id, :simulation_status, :disposition, :current_step, :questionnaire, submissions: []]

  def expired(respondent_id) do
    %QuestionnaireSimulationStep{respondent_id: respondent_id, simulation_status: Status.expired}
  end

  def build(%{respondent: respondent, submissions: submissions, questionnaire: quiz, section_order: section_order}, current_step, status, with_quiz) do
    step = %{
      respondent_id: respondent.id,
      simulation_status: status,
      disposition: respondent.disposition,
      current_step: current_step,
      submissions: submissions
    }
    if with_quiz, do: Map.put(step, :questionnaire, sort_quiz_sections(quiz, section_order)), else: step
  end

  defp sort_quiz_sections(quiz, nil), do: quiz
  defp sort_quiz_sections(quiz, section_order) do
    sorted_steps = section_order |> Enum.reduce([], fn index, acc -> acc ++ [quiz.steps |> Enum.at(index)] end)
    %{quiz | steps: sorted_steps}
  end
end

defmodule Ask.QuestionnaireMobileWebSimulationStep do
  defstruct [:respondent_id, :simulation_status, :disposition, :current_step, :reply, :questionnaire, submissions: []]

  def start_build(simulation, current_step, status, reply) do
    simulation_step = Ask.QuestionnaireSimulationStep.build(simulation, current_step, status, true)
    Map.merge(%Ask.QuestionnaireMobileWebSimulationStep{reply: reply}, simulation_step)
  end
  def sync_build(simulation, current_step, status, reply) do
    simulation_step = Ask.QuestionnaireSimulationStep.build(simulation, current_step, status, false)
    Map.merge(%Ask.QuestionnaireMobileWebSimulationStep{reply: reply}, simulation_step)
  end
end

defmodule Ask.QuestionnaireSmsSimulationStep do
  defstruct [:respondent_id, :simulation_status, :disposition, :current_step, :questionnaire, messages_history: [], submissions: []]

  def start_build(simulation, current_step, status, messages_history) do
    simulation_step = Ask.QuestionnaireSimulationStep.build(simulation, current_step, status, true)
    Map.merge(%Ask.QuestionnaireSmsSimulationStep{messages_history: messages_history}, simulation_step)
  end

  def sync_build(simulation, current_step, status, messages_history) do
    simulation_step = Ask.QuestionnaireSimulationStep.build(simulation, current_step, status, false)
    Map.merge(%Ask.QuestionnaireSmsSimulationStep{messages_history: messages_history}, simulation_step)
  end
end

defmodule Ask.QuestionnaireIvrSimulationStep do
  defstruct [:respondent_id, :simulation_status, :disposition, :current_step, :questionnaire, messages_history: [], prompts: [], submissions: []]

  def start_build(simulation, current_step, status, messages_history, prompts) do
    simulation_step = Ask.QuestionnaireSimulationStep.build(simulation, current_step, status, true)
    Map.merge(%Ask.QuestionnaireIvrSimulationStep{messages_history: messages_history, prompts: prompts}, simulation_step)
  end

  def sync_build(simulation, current_step, status, messages_history, prompts) do
    simulation_step = Ask.QuestionnaireSimulationStep.build(simulation, current_step, status, false)
    Map.merge(%Ask.QuestionnaireIvrSimulationStep{messages_history: messages_history, prompts: prompts}, simulation_step)
  end
end

defmodule Ask.Runtime.SimulatorChannel do
  defstruct patterns: []
end

defmodule Ask.Runtime.QuestionnaireSimulator do
  alias Ask.{Survey, Respondent, Questionnaire, Project, SystemTime, Runtime, QuestionnaireSimulationStep}
  alias Ask.Simulation.{Status, AOMessage, SubmittedStep, Response}
  alias Ask.Runtime.{Session, QuestionnaireSimulatorStore, QuestionnaireSmsSimulator, QuestionnaireIvrSimulator, QuestionnaireMobileWebSimulator}

  def start_simulation(project, questionnaire, mode) do
    if valid_questionnaire?(questionnaire, mode) do
      case mode do
        "sms" ->
          QuestionnaireSmsSimulator.start(project, questionnaire)
        "ivr" ->
          QuestionnaireIvrSimulator.start(project, questionnaire)
        "mobileweb" ->
          QuestionnaireMobileWebSimulator.start(project, questionnaire)
        _ ->
          Response.invalid_simulation
      end
    else
      Response.invalid_simulation
    end
  end

  def process_respondent_response(respondent_id, response, mode) do
    case mode do
      "sms" ->
        Ask.Runtime.QuestionnaireSmsSimulator.process_respondent_response(respondent_id, response)
      "ivr" ->
        Ask.Runtime.QuestionnaireIvrSimulator.process_respondent_response(respondent_id, response)
      "mobileweb" ->
        Ask.Runtime.QuestionnaireMobileWebSimulator.process_respondent_response(respondent_id, response)
    end
  end

  def process_respondent_response(respondent_id, response, build_simulation, sync_simulation) do
    simulation = QuestionnaireSimulatorStore.get_respondent_simulation(respondent_id)
    if (simulation) do
      {:ok, %{simulation: simulation, simulation_response: simulation_response}} = sync_simulation.(simulation, response)
      QuestionnaireSimulatorStore.add_respondent_simulation(respondent_id, build_simulation.(simulation, simulation_response))
      simulation_response
    else
      respondent_id
      |> QuestionnaireSimulationStep.expired
      |> Response.success
    end
  end

  def sync_simulation(simulation, reply, mode, handle_app_reply) do
    case Runtime.Survey.sync_step(simulation.respondent, reply, mode, SystemTime.time.now, false) do
      {:reply, reply, respondent} ->
        handle_app_reply.(simulation, respondent, reply, Status.active)
      {:end, {:reply, reply}, respondent} ->
        handle_app_reply.(simulation, respondent, reply, Status.ended)
      {:end, respondent} ->
        handle_app_reply.(simulation, respondent, nil, Status.ended)
    end
  end

  defp valid_questionnaire?(quiz, mode), do: quiz.modes |> Enum.member?(mode)

  def start(%Project{} = project, %Questionnaire{} = questionnaire, mode, start_build, options \\ []) do
    delivery_confirm = Keyword.get(options, :delivery_confirm, nil)
    append_last_simulation_response = Keyword.get(options, :append_last_simulation_response, nil)

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
      disposition: :queued,
      phone_number: "",
      canonical_phone_number: "",
      sanitized_phone_number: "",
      responses: []
    }

    # Simulating what Broker does when starting a respondent: Session.start and then Survey.handle_session_step
    session_started = Session.start(questionnaire, new_respondent, %Ask.Runtime.SimulatorChannel{}, mode, Ask.Schedule.always(), [], nil, nil, [], nil, false, false)
    {:reply, reply, respondent} = Runtime.Survey.handle_session_step(session_started, SystemTime.time.now, false)

    respondent = if delivery_confirm, do: delivery_confirm.(respondent), else: respondent
    %{simulation: simulation, response: response} = start_build.(respondent, reply)
    simulation = if (append_last_simulation_response) do
      append_last_simulation_response.(simulation, response)
    else
      simulation
    end
    QuestionnaireSimulatorStore.add_respondent_simulation(respondent.id, simulation)
    response
  end

  # Must update the respondent.session's respondent since if not will be outdated from respondent
  # This is necessary since some flows:
  #  - start using the respondent,
  #  - then use the respondent.session
  #  - and after that use the session.respondent
  #
  # If not synced, respondent data would be loss during simulation and the simulation could behave inaccurately
  def sync_respondent(respondent) do
    synced_session = if respondent.session, do: %{respondent.session | respondent: respondent}, else: respondent.session
    %{respondent | session: synced_session}
  end

  def handle_app_reply(simulation, respondent, reply, status, sync_build) do
    submitted_steps = simulation.submissions ++ SubmittedStep.build_from_responses(respondent, simulation) ++ SubmittedStep.new_explanations(reply)
    current_step = current_step(reply)

    simulation = %{simulation | respondent: sync_respondent(respondent), submissions: submitted_steps}
    simulation_response =
      simulation
      |> sync_build.(current_step, status, reply)
      |> Response.success
    {:ok, %{simulation: simulation, simulation_response: simulation_response}}
  end

  def current_step(reply) do
    case Ask.Runtime.Reply.steps(reply) |> List.last do
      nil -> nil
      step -> step.id
    end
  end

  def base_simulation(questionnaire, respondent) do
    section_order = respondent.session.flow.section_order
    respondent = sync_respondent(respondent)
    %{
      questionnaire: questionnaire,
      respondent: respondent,
      submissions: [],
      section_order: section_order
    }
  end
end

defmodule Ask.Runtime.QuestionnaireMobileWebSimulator do
  alias Ask.Runtime.{Survey, QuestionnaireSimulator, QuestionnaireSimulatorStore, Flow}
  alias Ask.{QuestionnaireMobileWebSimulation, QuestionnaireMobileWebSimulationStep, QuestionnaireSimulationStep}
  alias Ask.Simulation.{Status, Response}
  def start(project, questionnaire) do
    start_build = fn respondent, reply ->
      base_simulation = QuestionnaireSimulator.base_simulation(questionnaire, respondent)
      simulation = Map.merge(%QuestionnaireMobileWebSimulation{}, base_simulation)
      current_step = QuestionnaireSimulator.current_step(reply)

      response =
        simulation
        |> QuestionnaireMobileWebSimulationStep.start_build(current_step, Status.active, reply)
        |> Response.success

      %{simulation: simulation, response: response}
    end

    append_last_simulation_response = fn simulation, response ->
      %{simulation | last_simulation_response: response}
    end

    QuestionnaireSimulator.start(project, questionnaire, "mobileweb", start_build, append_last_simulation_response: append_last_simulation_response)
  end

  def process_respondent_response(respondent_id, response) do
    build_simulation = fn simulation, simulation_response ->
      %Ask.QuestionnaireMobileWebSimulation{simulation | last_simulation_response: simulation_response}
    end

    sync_build = fn simulation, current_step, status, reply ->
      QuestionnaireMobileWebSimulationStep.sync_build(simulation, current_step, status, reply)
    end

    handle_app_reply = fn simulation, respondent, reply, status ->
      QuestionnaireSimulator.handle_app_reply(simulation, respondent, reply, status, sync_build)
    end

    sync_simulation = fn simulation, response ->
      reply = if response == :answer, do: :answer, else: Flow.Message.reply(response)
      QuestionnaireSimulator.sync_simulation(simulation, reply, "mobileweb", handle_app_reply)
    end

    QuestionnaireSimulator.process_respondent_response(respondent_id, response, build_simulation, sync_simulation)
  end

  def get_last_simulation_response(respondent_id) do
    simulation = QuestionnaireSimulatorStore.get_respondent_simulation(respondent_id)
    if (simulation) do
      last_simulation_response = Map.get(simulation, :last_simulation_response)
      if (last_simulation_response) do
        last_simulation_response
      else
        Response.invalid_simulation
      end
    else
      respondent_id
      |> QuestionnaireSimulationStep.expired
      |> Response.success
    end
  end

end

defmodule Ask.Runtime.QuestionnaireSmsSimulator do
  alias Ask.Runtime.{Survey, QuestionnaireSimulator, Flow}
  alias Ask.{QuestionnaireSmsSimulation, QuestionnaireSmsSimulationStep}
  alias Ask.Simulation.{AOMessage, ATMessage, Status, Response, SubmittedStep}
  def start(project, questionnaire) do
    start_build = fn respondent, reply ->
      base_simulation = QuestionnaireSimulator.base_simulation(questionnaire, respondent)
      messages = AOMessage.create_all(reply)
      simulation = Map.merge(base_simulation, %{
        submissions: SubmittedStep.new_explanations(reply),
        messages: messages
      })
      simulation = Map.merge(%QuestionnaireSmsSimulation{}, simulation)
      current_step = QuestionnaireSimulator.current_step(reply)

      response =
        simulation
        |> QuestionnaireSmsSimulationStep.start_build(current_step, Status.active, messages)
        |> Response.success

      %{simulation: simulation, response: response}
    end

    delivery_confirm = fn respondent ->
      # Simulating Nuntium confirmation on message delivery
      %{respondent: respondent} = Survey.delivery_confirm(QuestionnaireSimulator.sync_respondent(respondent), "", "sms", false)
      respondent
    end

    QuestionnaireSimulator.start(project, questionnaire, "sms", start_build, delivery_confirm: delivery_confirm)
  end

  def process_respondent_response(respondent_id, response) do
    build_simulation = fn simulation, _simulation_response ->
      Map.merge(%QuestionnaireSmsSimulation{}, simulation)
    end

    handle_app_reply = fn simulation, respondent, reply, status ->
      messages = simulation.messages ++ AOMessage.create_all(reply)
      simulation = Map.put(simulation, :messages, messages)

      sync_build = fn simulation, current_step, status, _reply ->
        QuestionnaireSmsSimulationStep.sync_build(simulation, current_step, status, messages)
      end

      QuestionnaireSimulator.handle_app_reply(simulation, respondent, reply, status, sync_build)
    end

    sync_simulation = fn simulation, response ->
      messages = simulation.messages ++ [ATMessage.new(response)]
      simulation = %{simulation | messages: messages}
      reply = Flow.Message.reply(response)
      QuestionnaireSimulator.sync_simulation(simulation, reply, "sms", handle_app_reply)
    end

    QuestionnaireSimulator.process_respondent_response(respondent_id, response, build_simulation, sync_simulation)
  end
end

defmodule Ask.Runtime.QuestionnaireIvrSimulator do
  alias Ask.Runtime.{Survey, QuestionnaireSimulator, Flow}
  alias Ask.{QuestionnaireIvrSimulation, QuestionnaireIvrSimulationStep}
  alias Ask.Simulation.{AOMessage, ATMessage, IvrPrompt, Status, Response, SubmittedStep}

  def start(project, questionnaire) do
    start_build = fn respondent, reply ->
      base_simulation = QuestionnaireSimulator.base_simulation(questionnaire, respondent)
      messages = AOMessage.create_all(reply)
      prompts = IvrPrompt.create_all(reply)

      simulation = Map.merge(base_simulation, %{
        submissions: SubmittedStep.new_explanations(reply),
        messages: messages
      })
      simulation = Map.merge(%QuestionnaireIvrSimulation{}, simulation)
      current_step = QuestionnaireSimulator.current_step(reply)

      response =
        simulation
        |> QuestionnaireIvrSimulationStep.start_build(current_step, Status.active, messages, prompts)
        |> Response.success

      %{simulation: simulation, response: response}
    end

    delivery_confirm = fn respondent ->
      # Simulating Verboice confirmation on message delivery
      %{respondent: respondent} = Survey.delivery_confirm(QuestionnaireSimulator.sync_respondent(respondent), "", "ivr", false)
      respondent
    end

    QuestionnaireSimulator.start(project, questionnaire, "ivr", start_build, delivery_confirm: delivery_confirm)
  end

  def process_respondent_response(respondent_id, response) do
    build_simulation = fn simulation, _simulation_response ->
      Map.merge(%QuestionnaireIvrSimulation{}, simulation)
    end

    handle_app_reply = fn simulation, respondent, reply, status ->
      messages = simulation.messages ++ AOMessage.create_all(reply)
      simulation = Map.put(simulation, :messages, messages)

      sync_build = fn simulation, current_step, status, reply ->
        prompts = IvrPrompt.create_all(reply)
        QuestionnaireIvrSimulationStep.sync_build(simulation, current_step, status, messages, prompts)
      end

      QuestionnaireSimulator.handle_app_reply(simulation, respondent, reply, status, sync_build)
    end

    sync_simulation = fn simulation, response ->
      messages = simulation.messages ++ [ATMessage.new(response)]
      simulation = %{simulation | messages: messages}

      reply = Flow.Message.reply(response)
      QuestionnaireSimulator.sync_simulation(simulation, reply, "ivr", handle_app_reply)
    end

    QuestionnaireSimulator.process_respondent_response(respondent_id, response, build_simulation, sync_simulation)
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
      case prompt do
        %{"text" => body} -> %{body: body, type: "ao"}
        _ -> %{body: prompt, type: "ao"}
      end
    end
  end
end

defmodule Ask.Simulation.IvrPrompt do
  def create_all(nil), do: []
  def create_all(reply) do
    Enum.map Ask.Runtime.Reply.prompts(reply), fn prompt ->
        prompt
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
