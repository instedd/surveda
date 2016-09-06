defmodule Ask.QuestionnaireController do
  use Ask.Web, :api_controller

  alias Ask.Questionnaire

  def index(conn, %{"project_id" => project_id}) do
    questionnaires = Repo.all(from q in Questionnaire, where: q.project_id == ^project_id)
    render(conn, "index.json", questionnaires: questionnaires)
  end

  def create(conn, %{"project_id" => project_id, "questionnaire" => questionnaire_params}) do
    questionnaire_params = Map.put(questionnaire_params, "project_id", project_id)
    changeset = Questionnaire.changeset(%Questionnaire{}, questionnaire_params)

    case Repo.insert(changeset) do
      {:ok, questionnaire} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", project_questionnaire_path(conn, :index, project_id))
        |> render("show.json", questionnaire: questionnaire)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    questionnaire = Repo.get!(Questionnaire, id)
    render(conn, "show.json", questionnaire: questionnaire)
  end

  def update(conn, %{"id" => id, "questionnaire" => questionnaire_params}) do
    questionnaire = Repo.get!(Questionnaire, id)
    changeset = Questionnaire.changeset(questionnaire, questionnaire_params)

    case Repo.update(changeset) do
      {:ok, questionnaire} ->
        render(conn, "show.json", questionnaire: questionnaire)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    questionnaire = Repo.get!(Questionnaire, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(questionnaire)

    send_resp(conn, :no_content, "")
  end
end
