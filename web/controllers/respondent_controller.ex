defmodule Ask.RespondentController do
  use Ask.Web, :api_controller

  alias Ask.Project
  alias Ask.Survey
  alias Ask.Respondent

  def index(conn, %{"project_id" => project_id, "survey_id" => survey_id} = params) do
    limit = Map.get(params, "limit", "")

    Project
    |> Repo.get!(project_id)
    |> authorize(conn)

    respondents = Survey
    |> Repo.get!(survey_id)
    |> assoc(:respondents)
    |> preload(:responses)

    respondents_count = respondents |> Repo.aggregate(:count, :id)

    respondents = respondents
    |> conditional_limit(limit)
    |> Repo.all

    respondents = mask_phone_numbers(respondents)

    render(conn, "index.json", respondents: respondents, respondents_count: respondents_count)
  end

  def conditional_limit query, limit do
    case limit do
      "" -> query
      number -> query |> limit(^number)
    end
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

  defp csv_rows(csv_string) do
    delimiters = ["\r\n", "\r", "\n"]
    [{_, delimiter} | _] =
      delimiters
      |> Enum.map(fn d ->
          case :binary.match(csv_string, d) do
            {index, _} -> {index, d}
            _ -> {d, -1}
          end
        end)
      |> Enum.filter(fn {index, _} -> index != -1 end)
      |> Enum.sort

    csv_string
    |> String.split(delimiter)
    |> Enum.filter(fn r ->
      length = r |> String.trim |> String.length
      length != 0
    end)
  end

  def render_respondents(conn, survey_id, rows) do
    {:ok, local_time } = Ecto.DateTime.cast :calendar.local_time()
    {integer_survey_id, _ } = Integer.parse survey_id

    entries = rows
      |> Enum.map(fn row ->
        %{phone_number: row, survey_id: integer_survey_id, inserted_at: local_time, updated_at: local_time}
      end)

    respondents_count = entries
      |> Enum.chunk(1_000, 1_000, []) |> Enum.reduce(0, fn(chunked_entries, total_count)  ->
        {count, _ } = Repo.insert_all(Respondent, chunked_entries)
        total_count + count
      end)

    respondents = mask_phone_numbers(Repo.all(from r in Respondent, where: r.survey_id == ^survey_id, limit: 5))

    update_survey_state(survey_id, respondents_count)

    conn
      |> put_status(:created)
      |> render("index.json", respondents: respondents |> Repo.preload(:responses), respondents_count: respondents_count)
  end

  def render_unprocessable_entity(conn) do
    conn
      |> put_status(:unprocessable_entity)
      |> render(Ask.ChangesetView, "error.json", changeset: change(%Respondent{}, %{}))
  end

  def render_invalid(conn, invalid_entries) do
    conn
      |> put_status(:unprocessable_entity)
      |> render("invalid_entries.json", %{invalid_entries: invalid_entries})
  end

  def create(conn, %{"project_id" => project_id, "file" => file, "survey_id" => survey_id}) do
    Project
    |> Repo.get!(project_id)
    |> authorize(conn)

    if Path.extname(file.filename) == ".csv" do
      rows =
        file.path
        |> File.read!
        |> csv_rows
        |> Enum.uniq

      indexed_rows = rows
                     |> Enum.with_index
                     |> Enum.map( fn {row, index} -> %{phone_number: row, line_number: index + 1} end)

      invalid_entries = Enum.filter(indexed_rows, fn entry -> !Regex.match?(~r/^([0-9]|\(|\)|\+|\-| )+$/, entry.phone_number) end)

      case invalid_entries do
        [] -> render_respondents(conn, survey_id, rows)
        _ -> render_invalid(conn, invalid_entries)
      end
    else
      render_unprocessable_entity(conn)
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
