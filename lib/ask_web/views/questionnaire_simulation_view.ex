defmodule AskWeb.QuestionnaireSimulationView do
  alias Ask.{QuestionnaireSmsSimulationStep, QuestionnaireIvrSimulationStep}
  use AskWeb, :view

  def render("simulation.json", %{
        simulation: %{respondent_id: respondent_id} = simulation,
        mode: "mobileweb"
      }) do
    render_simulation(simulation)
    |> Map.put(:index_url, "/mobile/simulation/#{respondent_id}")
  end

  def render("simulation.json", %{simulation: simulation}) do
    render_simulation(simulation)
  end

  defp render_simulation(
         %QuestionnaireSmsSimulationStep{
           messages_history: messages_history
         } = simulation
       ) do
    simulation = prepare_simulation(simulation)
    simulation = Map.put(simulation, :messages_history, messages_history)
    render_prepared_simulation(simulation)
  end

  defp render_simulation(
         %QuestionnaireIvrSimulationStep{
           messages_history: messages_history,
           prompts: prompts
         } = simulation
       ) do
    simulation = prepare_simulation(simulation)
    simulation = Map.put(simulation, :messages_history, messages_history)
    simulation = Map.put(simulation, :prompts, prompts)
    render_prepared_simulation(simulation)
  end

  defp render_simulation(simulation) do
    simulation = prepare_simulation(simulation)
    render_prepared_simulation(simulation)
  end

  defp prepare_simulation(%{
         respondent_id: respondent_id,
         simulation_status: simulation_status,
         disposition: disposition,
         submissions: submissions,
         current_step: current_step,
         questionnaire: questionnaire
       }) do
    %{
      respondent_id: respondent_id,
      simulation_status: simulation_status,
      disposition: disposition,
      submissions: submissions,
      current_step: current_step,
      questionnaire:
        AskWeb.QuestionnaireView.render("questionnaire.json", %{questionnaire: questionnaire})
    }
  end

  defp render_prepared_simulation(simulation) do
    Enum.filter(simulation, fn {_, value} -> value end)
    |> Map.new()
  end
end
