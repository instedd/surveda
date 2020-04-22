defmodule Ask.QuestionnaireSimulation do
  defstruct [:respondent, :questionnaire, :messages]
end

defmodule Ask.SimulatorChannel do
  defstruct patterns: []
end

defmodule Ask.QuestionnaireSimulator do
  use Agent

  alias Ask.{Survey, Respondent, Questionnaire, Project, SystemTime, Runtime}
  alias Ask.Runtime.{Session, Flow}

  def start_link() do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def add_respondent_simulation(respondent_id, simulation_status) do
    Agent.update(Ask.QuestionnaireSimulator, &Map.put(&1, respondent_id, simulation_status))
  end

  def get_respondent_status(respondent_id) do
    Agent.get(Ask.QuestionnaireSimulator, &Map.get(&1, respondent_id))
  end

  defp adapt_questionnaire(questionnaire) do
    adapted_steps = questionnaire.steps |> Enum.map(fn step ->
      prompts = step["prompt"] |> Enum.map(fn {lang, prompt} -> {lang, Map.put(prompt, "sms_simulator", prompt["sms"])} end)
      choices = step["choices"] |> Enum.map(fn choice ->
        sms_simulator_responses = choice["responses"]["sms"]
        Map.put(choice, "responses", Map.put(choice["responses"], "sms_simulator", sms_simulator_responses)) end)
      step
      |> Map.put("prompt", prompts |> Enum.into(%{}))
      |> Map.put("choices", choices)
    end)

    adapted_settings = questionnaire.settings
                       |> Map.put("thank_you_message", questionnaire.settings["thank_you_message"] |> Enum.map(fn {lang, msg} -> {lang, Map.put(msg, "sms_simulator", msg["sms"])} end) |> Enum.into(%{}))
                       |> Map.put("error_message", questionnaire.settings["error_message"] |> Enum.map(fn {lang, msg} -> {lang, Map.put(msg, "sms_simulator", msg["sms"])} end) |> Enum.into(%{}))

    %{questionnaire | steps: adapted_steps, settings: adapted_settings}
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

    {:ok, session, _reply, _timeout} = session_started = Session.start(questionnaire, respondent, %Ask.SimulatorChannel{}, mode, Ask.Schedule.always(), [], nil, nil, [], nil, false, false)

    {:reply, reply, respondent} = Runtime.Survey.handle_session_step(session_started, SystemTime.time.now, false)

    reply_messages = reply_to_messages(reply)
    messages = AOMessage.new(reply_messages)
    updated_respondent = %Respondent{respondent | session: session |> Map.put(:questionnaire_id, questionnaire.id)}

    Ask.QuestionnaireSimulator.add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{questionnaire: questionnaire, respondent: updated_respondent, messages: messages})
    %{id: respondent.id, disposition: respondent.disposition, reply_messages: reply_messages, messages_history:  messages}
  end

  def process_respondent_response(respondent_id, response) do
    %{respondent: respondent, messages: messages} = simulation = Ask.QuestionnaireSimulator.get_respondent_status(respondent_id)
    updated_messages = messages ++ [ATMessage.new(response)]
    Ask.QuestionnaireSimulator.add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{simulation | messages: updated_messages})
    simulation = Ask.QuestionnaireSimulator.get_respondent_status(respondent_id)

    reply = Flow.Message.reply(response)

    case Runtime.Survey.sync_step(respondent, reply, "sms_simulator", SystemTime.time.now, false) do
      {:reply, reply, respondent} ->
        reply_messages = reply_to_messages(reply)
        messages = simulation.messages ++ AOMessage.new(reply_messages)
        Ask.QuestionnaireSimulator.add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{simulation | respondent: respondent, messages: messages})
        %{id: respondent.id, disposition: respondent.disposition, reply_messages: reply_messages, messages_history:  messages}
      {:end, {:reply, reply}, respondent} ->
        reply_messages = reply_to_messages(reply)
        messages = simulation.messages ++ AOMessage.new(reply_messages)
        Ask.QuestionnaireSimulator.add_respondent_simulation(respondent.id, %Ask.QuestionnaireSimulation{simulation | respondent: respondent, messages: messages})
        %{id: respondent.id, disposition: respondent.disposition, reply_messages: reply_messages, messages_history:  messages}
      {:end, respondent} -> %{id: respondent.id, disposition: respondent.disposition, reply_messages: nil, messages_history:  simulation.messages}
    end
  end

  def reply_to_messages(reply) do
    Enum.flat_map Ask.Runtime.Reply.steps(reply), fn step ->
      step.prompts |> Enum.with_index |> Enum.map(fn {prompt, index} ->
        %{
          body: prompt,
          step_title: Ask.Runtime.ReplyStep.title_with_index(step, index + 1)
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