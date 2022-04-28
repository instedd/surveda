defmodule Ask.QuestionnaireMobileWebSimulation do
  defstruct [
    :respondent,
    :questionnaire,
    :section_order,
    :last_simulation_response,
    submissions: []
  ]
end

defmodule Ask.QuestionnaireMobileWebSimulationStep do
  defstruct [
    :respondent_id,
    :simulation_status,
    :disposition,
    :current_step,
    :reply,
    :questionnaire,
    submissions: []
  ]

  def start_build(simulation, current_step, status, reply) do
    simulation_step =
      Ask.QuestionnaireSimulationStep.build(simulation, current_step, status, true)

    Map.merge(%Ask.QuestionnaireMobileWebSimulationStep{reply: reply}, simulation_step)
  end

  def sync_build(simulation, current_step, status, reply) do
    simulation_step =
      Ask.QuestionnaireSimulationStep.build(simulation, current_step, status, false)

    Map.merge(%Ask.QuestionnaireMobileWebSimulationStep{reply: reply}, simulation_step)
  end
end

defmodule Ask.Runtime.QuestionnaireMobileWebSimulator do
  alias Ask.Runtime.{QuestionnaireSimulator, QuestionnaireSimulatorStore, Flow}

  alias Ask.{
    QuestionnaireMobileWebSimulation,
    QuestionnaireMobileWebSimulationStep,
    QuestionnaireSimulationStep
  }

  alias Ask.Simulation.{Status, Response}

  def start(project, questionnaire) do
    start_build = fn respondent, reply ->
      base_simulation = QuestionnaireSimulator.base_simulation(questionnaire, respondent)
      simulation = Map.merge(%QuestionnaireMobileWebSimulation{}, base_simulation)
      current_step = QuestionnaireSimulator.current_step(reply)

      response =
        simulation
        |> QuestionnaireMobileWebSimulationStep.start_build(current_step, Status.active(), reply)
        |> Response.success()

      %{simulation: simulation, response: response}
    end

    append_last_simulation_response = fn simulation, response ->
      %{simulation | last_simulation_response: response}
    end

    QuestionnaireSimulator.start(project, questionnaire, "mobileweb", start_build,
      append_last_simulation_response: append_last_simulation_response
    )
  end

  def process_respondent_response(respondent_id, response) do
    build_simulation = fn simulation, simulation_response ->
      %Ask.QuestionnaireMobileWebSimulation{
        simulation
        | last_simulation_response: simulation_response
      }
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

    QuestionnaireSimulator.process_respondent_response(
      respondent_id,
      response,
      build_simulation,
      sync_simulation
    )
  end

  def get_last_simulation_response(respondent_id) do
    simulation = QuestionnaireSimulatorStore.get_respondent_simulation(respondent_id)

    if simulation do
      last_simulation_response = Map.get(simulation, :last_simulation_response)

      if last_simulation_response do
        last_simulation_response
      else
        Response.invalid_simulation()
      end
    else
      respondent_id
      |> QuestionnaireSimulationStep.expired()
      |> Response.success()
    end
  end
end
