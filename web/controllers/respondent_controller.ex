defmodule Ask.RespondentController do
  use Ask.Web, :api_controller

  alias Ask.Project
  alias Ask.Survey
  alias Ask.Respondent

  def index(conn,  %{"project_id" => project_id, "survey_id" => survey_id}) do
    Project
    |> Repo.get!(project_id)
    |> authorize(conn)

    respondents = Survey
    |> Repo.get!(survey_id)
    |> assoc(:respondents)
    |> preload(:responses)
    |> Repo.all

    respondents = mask_phone_numbers(respondents)

    render(conn, "index.json", respondents: respondents)
  end

  def stats(conn,  %{"project_id" => project_id, "survey_id" => survey_id}) do
    survey = Project
    |> Repo.get!(project_id)
    |> authorize(conn)
    |> assoc(:surveys)
    |> Repo.get!(survey_id)
    |> Repo.preload(:respondents)

    by_state = Repo.all(
      from r in Respondent, where: r.survey_id == ^survey_id,
      group_by: :state,
      select: {r.state, count("*")}) |> Enum.into(%{})

    respondents_by_date = Repo.all(
      from r in Respondent, where: r.survey_id == ^survey_id and r.state == "completed",
      group_by: fragment("DATE(completed_at)"),
      select: {fragment("DATE(completed_at)"), count("*")})

    target_value = survey.cutoff || length(survey.respondents)

    active = by_state["active"] || 0
    pending = by_state["pending"] || 0
    completed = by_state["completed"] || 0
    failed = by_state["failed"] || 0
    stats = %{
      id: survey.id,
      respondents_by_state: %{pending: pending, completed: completed, active: active, failed: failed },
      completed_by_date: %{
        respondents_by_date: respondents_by_date,
        target_value: target_value
      }
    }
    render(conn, "stats.json", stats: stats)
  end

  def create(conn, %{"project_id" => project_id, "file" => file, "survey_id" => survey_id}) do
    Project
    |> Repo.get!(project_id)
    |> authorize(conn)

    {integer_survey_id, _ } = Integer.parse survey_id
    {:ok, local_time } = Ecto.DateTime.cast :calendar.local_time()

    if Path.extname(file.filename) == ".csv" do
      entries = File.stream!(file.path) |>
      CSV.decode(separator: ?\t) |>
      Enum.map(fn row ->
        %{phone_number: Enum.at(row, 0), survey_id: integer_survey_id, inserted_at: local_time, updated_at: local_time}
      end)

      {respondents_count, _ } = Repo.insert_all(Respondent, entries)

      respondents = mask_phone_numbers(Repo.all(from r in Respondent, where: r.survey_id == ^survey_id))

      update_survey_state(survey_id, respondents_count)

      conn
        |> put_status(:created)
        |> render("index.json", respondents: respondents |> Repo.preload(:responses))
    else
      conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: file)
    end
  end

  def delete(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    Project
    |> Repo.get!(project_id)
    |> authorize(conn)

    from(r in Respondent, where: r.survey_id == ^survey_id)
    |> Repo.delete_all

    update_survey_state(survey_id, 0)

    conn
      |> put_status(:ok)
      |> render("empty.json", respondent: [])
  end

  def update_survey_state(survey_id, respondents_count) do
    survey = Repo.get!(Survey, survey_id)
    survey = Map.merge(survey, %{respondents_count: respondents_count})

    survey
    |> Repo.preload([:channels])
    |> change
    |> Survey.update_state
    |> Repo.update
  end

  def mask_phone_numbers(respondents) do
    masked = respondents
    |>
    Enum.map(fn respondent ->
      %{respondent | phone_number: Respondent.mask_phone_number(respondent.phone_number)}
    end)
    masked
  end

end
