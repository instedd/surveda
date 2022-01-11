defmodule Ask.QuestionnaireSimulationController do
  use Ask.Web, :api_controller
  use Ask.Web, :append_assigns_to_action

  alias Ask.Runtime.{QuestionnaireSimulator, QuestionnaireMobileWebSimulator}

  plug :assign_project when action in [:start, :sync, :get_last_response]

  action_fallback Ask.FallbackController

  def start(conn, %{"questionnaire_id" => id}, %{project: project}) do
    mode = conn.params["mode"]

    with {:ok, questionnaire} <- load_questionnaire(project, id),
         {:ok, simulation_response} <- QuestionnaireSimulator.start_simulation(project, questionnaire, mode)
    do
      render(conn, "simulation.json", simulation: simulation_response, mode: mode)
    end
  end

  def sync(conn, %{"respondent_id" => respondent_id, "response" => response, "mode" => mode}, _) do
    with {:ok, simulation_response} <- QuestionnaireSimulator.process_respondent_response(respondent_id, response, mode), do:
      render(conn, "simulation.json", simulation: simulation_response)
  end

  def get_last_response(conn, %{"respondent_id" => respondent_id}, _) do
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
