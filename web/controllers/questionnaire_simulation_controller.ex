defmodule Ask.QuestionnaireSimulationController do
  use Ask.Web, :api_controller

  alias Ask.Runtime.{QuestionnaireSimulator, QuestionnaireMobileWebSimulator}

  action_fallback Ask.FallbackController

  def start(conn, %{"project_id" => project_id, "questionnaire_id" => id}) do
    project = conn |> load_project(project_id)
    mode = conn.params["mode"]

    with {:ok, questionnaire} <- load_questionnaire(project, id),
         {:ok, simulation_response} <- QuestionnaireSimulator.start_simulation(project, questionnaire, mode)
    do
      render(conn, "simulation.json", simulation: simulation_response, mode: mode)
    end
  end

  def sync(conn, %{"respondent_id" => respondent_id, "response" => response, "mode" => mode}) do
    with {:ok, simulation_response} <- QuestionnaireSimulator.process_respondent_response(respondent_id, response, mode), do:
      render(conn, "simulation.json", simulation: simulation_response)
  end

  def get_last_response(conn, %{"respondent_id" => respondent_id}) do
    with {:ok, simulation_response} <- QuestionnaireMobileWebSimulator.get_last_simulation_response(respondent_id), do:
      render(conn, "simulation.json", simulation: simulation_response)
  end

  defp load_questionnaire(project, id) do
    questionnaire = project
    |> assoc(:questionnaires)
    |> where([q], q.deleted == false)
    |> Repo.get(id)

    case questionnaire do
      nil -> {:error, :not_found}
      _ -> {:ok, questionnaire}
    end
  end
end
