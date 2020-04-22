defmodule Ask.QuestionnaireSimulation do
  defstruct [:respondent, :questionnaire, :messages]
end

defmodule Ask.Runtime.SimulatorChannel do
  defstruct patterns: []
end

defmodule Ask.Runtime.QuestionnaireSimulator do
  use Agent

  alias Ask.{Survey, Respondent, Questionnaire, Project, SystemTime, Runtime}
  alias Ask.Runtime.{Session, Flow}

  def start_link() do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def add_respondent_simulation(respondent_id, simulation_status) do
    Agent.update(Ask.Runtime.QuestionnaireSimulator, &Map.put(&1, respondent_id, simulation_status))
  end

  def get_respondent_status(respondent_id) do
    Agent.get(Ask.Runtime.QuestionnaireSimulator, &Map.get(&1, respondent_id))
  end

  # Replicates all 'sms' configurations under 'sms_simulator' key
  defp adapt_questionnaire(questionnaire) do
    adapted_steps = questionnaire.steps |> Enum.map(fn step ->
      prompts = (step["prompt"] || %{})|> Enum.map(fn {lang, prompt} -> {lang, Map.put(prompt, "sms_simulator", prompt["sms"])} end)
      choices = (step["choices"] || []) |> Enum.map(fn choice ->
        sms_simulator_responses = choice["responses"]["sms"]
        Map.put(choice, "responses", Map.put(choice["responses"], "sms_simulator", sms_simulator_responses)) end)
      step
      |> Map.put("prompt", prompts |> Enum.into(%{}))
      |> Map.put("choices", choices)
    end)

    modes = questionnaire.modes ++ ["sms_simulator"]
    adapted_settings = questionnaire.settings
                       |> Map.put("thank_you_message", (questionnaire.settings["thank_you_message"] || []) |> Enum.map(fn {lang, msg} -> {lang, Map.put(msg, "sms_simulator", msg["sms"])} end) |> Enum.into(%{}))
                       |> Map.put("error_message", (questionnaire.settings["error_message"] || [] )|> Enum.map(fn {lang, msg} -> {lang, Map.put(msg, "sms_simulator", msg["sms"])} end) |> Enum.into(%{}))

    %{questionnaire | steps: adapted_steps, settings: adapted_settings, modes: modes}
  end

  def start_simulation(%Project{} = project, %Questionnaire{} = questionnaire, mode \\ "sms_simulator") do
    questionnaire = adapt_questionnaire(questionnaire)
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

    respondent = %Respondent{
      id: Ecto.UUID.generate(),
      survey_id: survey.id,
      survey: survey,
      questionnaire_id: questionnaire.id,
      mode: [mode],
      disposition: "queued",
      phone_number: "",
      canonical_phone_number: "",
      sanitized_phone_number: ""
    }

    {:ok, session, _reply, _timeout} = session_started = Session.start(questionnaire, respondent, %Ask.Runtime.SimulatorChannel{}, mode, Ask.Schedule.always(), [], nil, nil, [], nil, false, false)

    {:reply, reply, respondent} = Runtime.Survey.handle_session_step(session_started, SystemTime.time.now, false)
    respondent = %{respondent | session: inflate_session(respondent, respondent.session, questionnaire)}
    reply_messages = reply_to_messages(reply)
    messages = AOMessage.new(reply_messages)
    updated_respondent = %Respondent{respondent | session: session}

    add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{questionnaire: questionnaire, respondent: updated_respondent, messages: messages})
    %{id: respondent.id, disposition: respondent.disposition, reply_messages: reply_messages, messages_history:  messages}
  end

  def inflate_session(respondent, session, questionnaire) do
      state = session.flow
      flow = %Flow{questionnaire: questionnaire, current_step: state.current_step, mode: state.mode, language: state.language, retries: state.retries, in_quota_completed_steps: state.in_quota_completed_steps, has_sections: Ask.Runtime.Flow.questionnaire_has_sections(questionnaire), section_order: state.section_order, ignored_values_from_relevant_steps: Ask.Runtime.Flow.ignored_values_from_relevant_steps(questionnaire)}

      session = %Session{
        current_mode: Ask.Runtime.SessionModeProvider.new("sms_simulator", %Ask.Runtime.SimulatorChannel{}, []),
        fallback_mode: nil,
        flow: flow,
        respondent: Ask.Runtime.Session.update_section_order(respondent, flow.section_order, false),
        fallback_delay: Survey.default_fallback_delay(),
        count_partial_results: false,
        schedule: Ask.Schedule.always()
      }
      session
  end

  def process_respondent_response(respondent_id, response) do
    %{respondent: respondent, messages: messages} = simulation = get_respondent_status(respondent_id)
    updated_messages = messages ++ [ATMessage.new(response)]
    add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{simulation | messages: updated_messages})
    simulation = get_respondent_status(respondent_id)
#    session = simulation.respondent.session
    reply = Flow.Message.reply(response)

    case Runtime.Survey.sync_step(respondent, reply, "sms_simulator", SystemTime.time.now, false) do
      {:reply, reply, respondent} ->
        reply_messages = reply_to_messages(reply)
        messages = simulation.messages ++ AOMessage.new(reply_messages)
        respondent = %{respondent | session: inflate_session(respondent, respondent.session, simulation.questionnaire)}
        add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{simulation | respondent: respondent, messages: messages})
        %{id: respondent.id, disposition: respondent.disposition, reply_messages: reply_messages, messages_history:  messages}
      {:end, {:reply, reply}, respondent} ->
        reply_messages = reply_to_messages(reply)
        messages = simulation.messages ++ AOMessage.new(reply_messages)
        add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{simulation | respondent: respondent, messages: messages})
        %{id: respondent.id, disposition: respondent.disposition, reply_messages: reply_messages, messages_history:  messages}
      {:end, respondent} ->
        add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{simulation | respondent: respondent})
        %{id: respondent.id, disposition: respondent.disposition, reply_messages: nil, messages_history:  simulation.messages}
    end
  end

  def reply_to_messages(reply) do
    Enum.flat_map Ask.Runtime.Reply.steps(reply), fn step ->
      step.prompts |> Enum.with_index |> Enum.map(fn {prompt, index} ->
        %{
          body: prompt,
          title: Ask.Runtime.ReplyStep.title_with_index(step, index + 1)
        }
      end)
    end
  end
end

defmodule AOMessage do
  def new(messages) do
    messages |> Enum.map(fn msg -> msg |> Map.put(:type, "ao") end)
  end
end

defmodule ATMessage do
  def new(response) do
    %{body: response, type: "at"}
  end
end