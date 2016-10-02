defmodule Ask.QuestionnaireController do
  use Ask.Web, :api_controller

  alias Ask.Questionnaire
  alias Ask.Project

  def index(conn, %{"project_id" => project_id}) do
    questionnaires = Project
    |> Repo.get!(project_id)
    |> authorize(conn)
    |> assoc(:questionnaires)
    |> Repo.all

    render(conn, "index.json", questionnaires: questionnaires)
  end

  def create(conn, %{"project_id" => project_id, "questionnaire" => params}) do
    params = params
    |> Map.put_new("steps", dummy_steps())

    changeset = Project
    |> Repo.get!(project_id)
    |> authorize(conn)
    |> build_assoc(:questionnaires)
    |> Questionnaire.changeset(params)

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

  def show(conn, %{"project_id" => project_id, "id" => id}) do
    questionnaire = Project
    |> Repo.get!(project_id)
    |> authorize(conn)
    |> assoc(:questionnaires)
    |> Repo.get!(id)

    render(conn, "show.json", questionnaire: questionnaire)
  end

  def update(conn, %{"project_id" => project_id, "id" => id, "questionnaire" => params}) do
    params = params
    |> Map.put_new("steps", dummy_steps())

    changeset = Project
    |> Repo.get!(project_id)
    |> authorize(conn)
    |> assoc(:questionnaires)
    |> Repo.get!(id)
    |> Questionnaire.changeset(params)

    case Repo.update(changeset) do
      {:ok, questionnaire} ->
        render(conn, "show.json", questionnaire: questionnaire)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"project_id" => project_id, "id" => id}) do
    Project
    |> Repo.get!(project_id)
    |> authorize(conn)
    |> assoc(:questionnaires)
    |> Repo.get!(id)
    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    |> Repo.delete!

    send_resp(conn, :no_content, "")
  end

  defp dummy_steps do
    [
      %{
        "id": "17141bea-a81c-4227-bdda-f5f69188b0e7",
        "type": "multiple-choice",
        "title": "Do you smoke?",
        "store": "Smokes",
        "choices": [
          %{
            "value": "Yes",
            "responses": ["Yes", "Y", "1"]
          },
          %{
            "value": "No",
            "responses": ["No", "N", "1"]
          }
        ]
      },
      %{
        "id": "b6588daa-cd81-40b1-8cac-ff2e72a15c15",
        "type": "multiple-choice",
        "title": "Do you exercise?",
        "store": "Exercises",
        "choices": [
          %{
            "value": "Yes",
            "responses": ["Yes", "Y", "1"]
          },
          %{
            "value": "No",
            "responses": ["No", "N", "1"]
          }
        ]
      },
      %{
        "id" => "c6588daa-cd81-40b1-8cac-ff2e72a15c15",
        "type" => "numeric",
        "title" => "Which is the second perfect number?",
        "store" => "Perfect Number",
      }
    ]
  end
end
