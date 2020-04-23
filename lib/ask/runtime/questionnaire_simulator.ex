defmodule Ask.QuestionnaireSimulation do
  defstruct [:respondent, :questionnaire, :messages]
end

defmodule Ask.Runtime.SimulatorChannel do
  defstruct patterns: []
end

defmodule Ask.Runtime.QuestionnaireSimulatorStore do
  use GenServer
  alias Ask.Logger

  @ttl_minutes Ask.ConfigHelper.get_config(__MODULE__, :simulation_ttl, &String.to_integer/1)

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    Logger.info("Starting questionnaire simulator with simulation_ttl: #{@ttl_minutes}")
    :timer.send_after(1000, :clean)
    {:ok, %{}}
  end

  defp ttl_expired?({_key, {ts, _}}) do
    ttl_minutes_ago = Timex.shift(Ask.SystemTime.time().now, minutes: -@ttl_minutes)
    Timex.before?(ts, ttl_minutes_ago)
  end

  def handle_info(:clean, state) do
    old_keys = state |> Enum.filter(&ttl_expired?/1) |> Enum.map(fn {key, _} -> key end)
    new_state = old_keys |> Enum.reduce(state, fn key, accum -> Map.delete(accum, key) end)
    if(old_keys != []) do Logger.debug("Cleaning old simulations. Respondent ids: #{inspect old_keys}") end

    :timer.send_after(:timer.minutes(1), :clean)
    {:noreply, new_state}
  end

  def handle_call({:get_status, respondent_id}, _from, state) do
    status = state |> Map.get(respondent_id)
    {:reply, if status do elem(status, 1) else nil end, state}
  end

  def handle_call({:add_status, respondent_id, status}, _from, state) do
    new_state = state |> Map.put(respondent_id, {Ask.SystemTime.time().now, status})
    {:reply, status, new_state}
  end

  def add_respondent_simulation(respondent_id, simulation_status) do
    GenServer.call(__MODULE__, {:add_status, respondent_id, simulation_status})
  end

  def get_respondent_simulation(respondent_id) do
    GenServer.call(__MODULE__, {:get_status, respondent_id})
  end
end

defmodule Ask.Runtime.QuestionnaireSimulator do
  alias Ask.{Survey, Respondent, Questionnaire, Project, SystemTime, Runtime}
  alias Ask.Runtime.{Session, Flow, QuestionnaireSimulatorStore}

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

    QuestionnaireSimulatorStore.add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{questionnaire: questionnaire, respondent: updated_respondent, messages: messages})
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
    simulation = QuestionnaireSimulatorStore.get_respondent_simulation(respondent_id)
    if(simulation) do
      %{respondent: respondent, messages: messages} = simulation
      updated_messages = messages ++ [ATMessage.new(response)]
      simulation = QuestionnaireSimulatorStore.add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{simulation | messages: updated_messages})
      reply = Flow.Message.reply(response)

      case Runtime.Survey.sync_step(respondent, reply, "sms_simulator", SystemTime.time.now, false) do
        {:reply, reply, respondent} ->
          reply_messages = reply_to_messages(reply)
          messages = simulation.messages ++ AOMessage.new(reply_messages)
          respondent = %{respondent | session: inflate_session(respondent, respondent.session, simulation.questionnaire)}
          QuestionnaireSimulatorStore.add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{simulation | respondent: respondent, messages: messages})
          %{id: respondent.id, disposition: respondent.disposition, reply_messages: reply_messages, messages_history:  messages}
        {:end, {:reply, reply}, respondent} ->
          reply_messages = reply_to_messages(reply)
          messages = simulation.messages ++ AOMessage.new(reply_messages)
          QuestionnaireSimulatorStore.add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{simulation | respondent: respondent, messages: messages})
          %{id: respondent.id, disposition: respondent.disposition, reply_messages: reply_messages, messages_history:  messages}
        {:end, respondent} ->
          QuestionnaireSimulatorStore.add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{simulation | respondent: respondent})
          %{id: respondent.id, disposition: respondent.disposition, reply_messages: nil, messages_history:  simulation.messages}
      end
    else
      :simulation_expired
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