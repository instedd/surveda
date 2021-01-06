defmodule Ask.QuestionnaireView do
  alias Ask.QuestionnaireSmsSimulationStep
  use Ask.Web, :view

  def render("index.json", %{questionnaires: questionnaires}) do
    %{data: render_many(questionnaires, Ask.QuestionnaireView, "questionnaire.json")}
  end

  def render("show.json", %{questionnaire: questionnaire}) do
    %{data: render_one(questionnaire, Ask.QuestionnaireView, "questionnaire.json")}
  end

  def render("questionnaire.json", %{questionnaire: nil}), do: nil

  def render("questionnaire.json", %{questionnaire: questionnaire}) do
    %{id: questionnaire.id,
      name: questionnaire.name,
      description: questionnaire.description,
      modes: questionnaire.modes,
      updated_at: questionnaire.updated_at,
      project_id: questionnaire.project_id,
      steps: questionnaire.steps,
      quota_completed_steps: questionnaire.quota_completed_steps,
      default_language: questionnaire.default_language,
      languages: questionnaire.languages,
      settings: questionnaire.settings,
      valid: questionnaire.valid,
      partial_relevant_config: questionnaire.partial_relevant_config,
      archived: questionnaire.archived
    }
  end

  def render("simulation.json", %{simulation: %{respondent_id: respondent_id} = simulation, mode: "mobileweb"}) do
    render_simulation(simulation)
    |> Map.put(:index_url, "/mobile/simulation/#{respondent_id}")
  end

  def render("simulation.json", %{simulation: simulation}) do
    render_simulation(simulation)
  end

  defp render_simulation(%QuestionnaireSmsSimulationStep{
    messages_history: messages_history,
  } = simulation) do
    simulation = prepare_simulation(simulation)
    simulation = Map.put(simulation, :messages_history, messages_history)
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
      questionnaire: render("questionnaire.json", %{questionnaire: questionnaire})
    }
  end

  defp render_prepared_simulation(simulation) do
    Enum.filter(simulation, fn {_, value} -> value end)
    |> Map.new()
  end
end
