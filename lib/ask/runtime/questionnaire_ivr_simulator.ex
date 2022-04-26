defmodule Ask.QuestionnaireIvrSimulation do
  defstruct [:respondent, :questionnaire, :section_order, messages: [], submissions: []]
end

defmodule Ask.QuestionnaireIvrSimulationStep do
  defstruct [
    :respondent_id,
    :simulation_status,
    :disposition,
    :current_step,
    :questionnaire,
    messages_history: [],
    prompts: [],
    submissions: []
  ]

  def start_build(simulation, current_step, status, messages_history, prompts) do
    simulation_step =
      Ask.QuestionnaireSimulationStep.build(simulation, current_step, status, true)

    Map.merge(
      %Ask.QuestionnaireIvrSimulationStep{messages_history: messages_history, prompts: prompts},
      simulation_step
    )
  end

  def sync_build(simulation, current_step, status, messages_history, prompts) do
    simulation_step =
      Ask.QuestionnaireSimulationStep.build(simulation, current_step, status, false)

    Map.merge(
      %Ask.QuestionnaireIvrSimulationStep{messages_history: messages_history, prompts: prompts},
      simulation_step
    )
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

      simulation =
        Map.merge(base_simulation, %{
          submissions: SubmittedStep.new_explanations(reply),
          messages: messages
        })

      simulation = Map.merge(%QuestionnaireIvrSimulation{}, simulation)
      current_step = QuestionnaireSimulator.current_step(reply)

      response =
        simulation
        |> QuestionnaireIvrSimulationStep.start_build(
          current_step,
          Status.active(),
          messages,
          prompts
        )
        |> Response.success()

      %{simulation: simulation, response: response}
    end

    delivery_confirm = fn respondent ->
      # Simulating Verboice confirmation on message delivery
      %{respondent: respondent} =
        Survey.delivery_confirm(
          QuestionnaireSimulator.sync_respondent(respondent),
          "",
          "ivr",
          false
        )

      respondent
    end

    QuestionnaireSimulator.start(project, questionnaire, "ivr", start_build,
      delivery_confirm: delivery_confirm
    )
  end

  def process_respondent_response(respondent_id, response) do
    build_simulation = fn simulation, _simulation_response ->
      Map.merge(%QuestionnaireIvrSimulation{}, simulation)
    end

    handle_app_reply = fn simulation, respondent, reply, status ->
      simulation = append_ao_message(simulation, reply)

      sync_build = fn simulation, current_step, status, reply ->
        prompts = IvrPrompt.create_all(reply)

        QuestionnaireIvrSimulationStep.sync_build(
          simulation,
          current_step,
          status,
          simulation.messages,
          prompts
        )
      end

      QuestionnaireSimulator.handle_app_reply(simulation, respondent, reply, status, sync_build)
    end

    sync_simulation = fn simulation, response ->
      if response == "hangup" do
        QuestionnaireSimulator.stop_simulation(simulation, handle_app_reply)
      else
        {simulation, reply} = handle_at_message(simulation, response)
        QuestionnaireSimulator.sync_simulation(simulation, reply, "ivr", handle_app_reply)
      end
    end

    QuestionnaireSimulator.process_respondent_response(
      respondent_id,
      response,
      build_simulation,
      sync_simulation
    )
  end

  defp append_ao_message(simulation, nil) do
    simulation
  end

  defp append_ao_message(simulation, reply) do
    messages = simulation.messages ++ AOMessage.create_all(reply)
    Map.put(simulation, :messages, messages)
  end

  defp handle_at_message(simulation, "timeout") do
    {simulation, Flow.Message.no_reply()}
  end

  defp handle_at_message(simulation, message) do
    messages = simulation.messages ++ [ATMessage.new(message)]
    simulation = Map.put(simulation, :messages, messages)
    {simulation, Flow.Message.reply(message)}
  end
end

defmodule Ask.Simulation.IvrPrompt do
  def create_all(nil), do: []

  def create_all(reply) do
    Enum.map(Ask.Runtime.Reply.prompts(reply), fn prompt ->
      prompt
    end)
  end
end
