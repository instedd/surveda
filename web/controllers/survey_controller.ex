defmodule Ask.SurveyController do
  use Ask.Web, :api_controller

  alias Ask.Survey
  alias Ask.SurveyChannel

  def index(conn, %{"project_id" => project_id}) do
    surveys = Repo.all(from s in Survey, where: s.project_id == ^project_id, preload: [:channels])
    render(conn, "index.json", surveys: surveys)
  end

  def create(conn, %{"project_id" => project_id}) do
    changeset = Survey.changeset(%Survey{}, %{project_id: project_id, name: "Untitled"})

    case Repo.insert(changeset) do
      {:ok, survey} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", project_survey_path(conn, :show, project_id, survey))
        |> render("show.json", survey: survey |> Repo.preload([:channels]))
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    survey = Repo.get!(Survey, id) |> Repo.preload([:channels])
    render(conn, "show.json", survey: survey)
  end

  def update(conn, %{"id" => id, "survey" => survey_params}) do
    survey = Repo.get!(Survey, id) |> Repo.preload([:channels])
    changeset = Survey.changeset(survey, survey_params)
    case Repo.update(changeset) do
      {:ok, survey} ->
        if survey_params["channel_id"] do
          {channel_id, _} = Integer.parse survey_params["channel_id"]
          changeset = Ecto.build_assoc(survey, :survey_channels, %{channel_id: channel_id})
          case Repo.insert(changeset) do
            {:ok, _} ->
              survey_id = survey.id
              to_delete_query = from sc in SurveyChannel, where: sc.survey_id == (^survey_id) and sc.channel_id != (^channel_id)
              Repo.delete_all(to_delete_query)
              survey = Repo.get!(Survey, id) |> Repo.preload([:channels])
              render(conn, "show.json", survey: survey)
            {:error, changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(Ask.ChangesetView, "error.json", changeset: changeset)
          end
        end
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  # defp update_changeset()
  # end

  def delete(conn, %{"id" => id}) do
    survey = Repo.get!(Survey, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(survey)

    send_resp(conn, :no_content, "")
  end
end
