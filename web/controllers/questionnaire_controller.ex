defmodule Ask.QuestionnaireController do
  use Ask.Web, :api_controller

  alias Ask.Questionnaire
  alias Ask.Project
  alias Ask.JsonSchema

  plug :validate_params when action in [:create, :update]

  def index(conn, %{"project_id" => project_id}) do
    questionnaires = Project
    |> Repo.get!(project_id)
    |> authorize(conn)
    |> assoc(:questionnaires)
    |> Repo.all

    render(conn, "index.json", questionnaires: questionnaires)
  end

  def create(conn, %{"project_id" => project_id}) do
    project = Project
    |> Repo.get!(project_id)
    |> authorize_change(conn)

    params = conn.assigns[:questionnaire]

    params = params
    |> Map.put_new("languages", ["en"])
    |> Map.put_new("default_language", "en")

    changeset = project
    |> build_assoc(:questionnaires)
    |> Questionnaire.changeset(params)

    case Repo.insert(changeset) do
      {:ok, questionnaire} ->
        project |> Project.touch!
        questionnaire |> Questionnaire.recreate_variables!
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

  def show(conn, %{"project_id" => project_id, "id" => id}) do
    questionnaire = Project
    |> Repo.get!(project_id)
    |> authorize(conn)
    |> assoc(:questionnaires)
    |> Repo.get!(id)

    render(conn, "show.json", questionnaire: questionnaire)
  end

  def update(conn, %{"project_id" => project_id, "id" => id}) do
    project = Project
    |> Repo.get!(project_id)
    |> authorize_change(conn)

    params = conn.assigns[:questionnaire]

    changeset = project
    |> assoc(:questionnaires)
    |> Repo.get!(id)
    |> Questionnaire.changeset(params)

    case Repo.update(changeset) do
      {:ok, questionnaire} ->
        project |> Project.touch!
        questionnaire |> Questionnaire.recreate_variables!
        questionnaire |> Ask.Translation.rebuild
        render(conn, "show.json", questionnaire: questionnaire)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"project_id" => project_id, "id" => id}) do
    project = Project
    |> Repo.get!(project_id)
    |> authorize_change(conn)

    project
    |> assoc(:questionnaires)
    |> Repo.get!(id)
    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    |> Repo.delete!

    project |> Project.touch!
    send_resp(conn, :no_content, "")
  end

  defp validate_params(conn, _params) do
    questionnaire = conn.params["questionnaire"]

    case JsonSchema.validate(questionnaire, :questionnaire) do
      [] ->
        conn |> assign(:questionnaire, questionnaire)
      errors ->
        json_errors = errors |> JsonSchema.errors_to_json
        IO.inspect("JSON SCHEMA VALIDATION FAILED")
        IO.inspect("-----------------------------")
        IO.inspect(json_errors)
        conn |> put_status(422) |> json(%{errors: json_errors}) |> halt
    end
  end
end
