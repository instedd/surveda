defmodule Ask.SurveyController do
  use Ask.Web, :api_controller

  alias Ask.{Project, Survey, Questionnaire}

  def index(conn, %{"project_id" => project_id}) do
    surveys = conn
    |> load_project(project_id)
    |> assoc(:surveys)
    |> Repo.all

    render(conn, "index.json", surveys: surveys)
  end

  def create(conn, params = %{"project_id" => project_id}) do
    project = conn
    |> load_project_for_change(project_id)

    props = %{"project_id" => project_id,
              "name" => "",
              "schedule_start_time" => Ecto.Time.cast!("09:00:00"),
              "schedule_end_time" => Ecto.Time.cast!("18:00:00"),
              "timezone" => "UTC"}
    survey_params = Map.get(params, "survey", %{})
    props = Map.merge(props, survey_params)

    changeset = project
    |> build_assoc(:surveys)
    |> Survey.changeset(props)

    case Repo.insert(changeset) do
      {:ok, survey} ->
        project |> Project.touch!
        conn
        |> put_status(:created)
        |> put_resp_header("location", project_survey_path(conn, :show, project_id, survey))
        |> render("show.json", survey: survey |> Repo.preload([:quota_buckets]))
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"project_id" => project_id, "id" => id}) do
    survey = conn
    |> load_project(project_id)
    |> assoc(:surveys)
    |> Repo.get!(id)
    |> Repo.preload([:quota_buckets])
    |> with_respondents_count

    render(conn, "show.json", survey: survey)
  end

  def update(conn, %{"project_id" => project_id, "id" => id, "survey" => survey_params}) do
    project = conn
    |> load_project_for_change(project_id)

    changeset = project
    |> assoc(:surveys)
    |> Repo.get!(id)
    |> Repo.preload([:questionnaires])
    |> Repo.preload([:quota_buckets])
    |> with_respondents_count
    |> Repo.preload(respondent_groups: :channels)
    |> Survey.changeset(survey_params)
    |> update_questionnaires(survey_params)
    |> Survey.update_state

    case Repo.update(changeset) do
      {:ok, survey} ->
        project |> Project.touch!
        render(conn, "show.json", survey: survey)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp update_questionnaires(changeset, %{"questionnaire_ids" => questionnaires_params}) do
    questionnaires_changeset = Enum.map(questionnaires_params, fn ch ->
      Repo.get!(Questionnaire, ch) |> change
    end)

    changeset
    |> put_assoc(:questionnaires, questionnaires_changeset)
  end

  defp update_questionnaires(changeset, _) do
    changeset
  end

  defp with_respondents_count(survey) do
    respondents_count = survey |> assoc(:respondents) |> select(count("*")) |> Repo.one
    %{survey | respondents_count: respondents_count}
  end

  def delete(conn, %{"project_id" => project_id, "id" => id}) do
    project = conn
    |> load_project_for_change(project_id)

    project
    |> assoc(:surveys)
    |> Repo.get!(id)
    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    |> Repo.delete!

    project |> Project.touch!

    send_resp(conn, :no_content, "")
  end

  def launch(conn, %{"survey_id" => id}) do
    survey = Repo.get!(Survey, id)
    |> Repo.preload([:quota_buckets])
    |> Repo.preload(respondent_groups: :channels)

    project = conn
    |> load_project_for_change(survey.project_id)

    channels = survey.respondent_groups
    |> Enum.flat_map(&(&1.channels))
    |> Enum.uniq

    case prepare_channels(conn, channels) do
      :ok ->
        changeset = Survey.changeset(survey, %{"state": "running", "started_at": Timex.now})
        case Repo.update(changeset) do
          {:ok, survey} ->
            project |> Project.touch!
            render(conn, "show.json", survey: survey)
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(Ask.ChangesetView, "error.json", changeset: changeset)
        end

      {:error, _reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("show.json", survey: survey)
    end
  end

  defp prepare_channels(_, []), do: :ok
  defp prepare_channels(conn, [channel | rest]) do
    runtime_channel = Ask.Channel.runtime_channel(channel)
    case Ask.Runtime.Channel.prepare(runtime_channel, callback_url(conn, :callback, channel.provider)) do
      {:ok, _} -> prepare_channels(conn, rest)
      error -> error
    end
  end
end
