defmodule Ask.QuestionnaireSmsSimulation do
  defstruct [:respondent, :questionnaire, :section_order, messages: [], submissions: []]
end

defmodule Ask.QuestionnaireSmsSimulationStep do
  defstruct [
    :respondent_id,
    :simulation_status,
    :disposition,
    :current_step,
    :questionnaire,
    messages_history: [],
    submissions: []
  ]

  def start_build(simulation, current_step, status, messages_history) do
    simulation_step =
      Ask.QuestionnaireSimulationStep.build(simulation, current_step, status, true)

    Map.merge(
      %Ask.QuestionnaireSmsSimulationStep{messages_history: messages_history},
      simulation_step
    )
  end

  def sync_build(simulation, current_step, status, messages_history) do
    simulation_step =
      Ask.QuestionnaireSimulationStep.build(simulation, current_step, status, false)

    Map.merge(
      %Ask.QuestionnaireSmsSimulationStep{messages_history: messages_history},
      simulation_step
    )
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

      simulation =
        Map.merge(base_simulation, %{
          submissions: SubmittedStep.new_explanations(reply),
          messages: messages
        })

      simulation = Map.merge(%QuestionnaireSmsSimulation{}, simulation)
      current_step = QuestionnaireSimulator.current_step(reply)

      response =
        simulation
        |> QuestionnaireSmsSimulationStep.start_build(current_step, Status.active(), messages)
        |> Response.success()

      %{simulation: simulation, response: response}
    end

    delivery_confirm = fn respondent ->
      # Simulating Nuntium confirmation on message delivery
      %{respondent: respondent} =
        Survey.delivery_confirm(
          QuestionnaireSimulator.sync_respondent(respondent),
          "",
          "sms",
          false
        )

      respondent
    end

    QuestionnaireSimulator.start(project, questionnaire, "sms", start_build,
      delivery_confirm: delivery_confirm
    )
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

    QuestionnaireSimulator.process_respondent_response(
      respondent_id,
      response,
      build_simulation,
      sync_simulation
    )
  end
end
