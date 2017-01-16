defmodule Ask.RespondentController do
  use Ask.Web, :api_controller

  alias Ask.{Project, Survey, Respondent, RespondentGroup, Response}

  def index(conn, %{"project_id" => project_id, "survey_id" => survey_id} = params) do
    limit = Map.get(params, "limit", "")
    page = Map.get(params, "page", "")

    respondents = conn
    |> load_project(project_id)
    |> assoc(:surveys)
    |> Repo.get!(survey_id)
    |> assoc(:respondents)
    |> preload(:responses)

    respondents_count = respondents |> Repo.aggregate(:count, :id)

    respondents = respondents
    |> conditional_limit(limit)
    |> conditional_page(limit, page)
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

  def conditional_page query, limit, page do
    limit_number = case limit do
      "" -> 10
      _ ->
        {limit_value, _} = Integer.parse(limit)
        limit_value
    end

    case page do
      "" -> query
      _ ->
        {page_number, _} = Integer.parse(page)
        offset = limit_number * (page_number - 1)
        query |> offset(^offset)
    end
  end

  def responded_on(datetime, by_date) do
    { date, _ } = datetime
    value = Enum.find(by_date, fn x -> elem(x, 0) == date end)
    if (value), do: value, else: {date, 0}
  end

  def stats(conn,  %{"project_id" => project_id, "survey_id" => survey_id}) do
    survey = conn
    |> load_project(project_id)
    |> assoc(:surveys)
    |> Repo.get!(survey_id)

    by_state = Repo.all(
      from r in Respondent, where: r.survey_id == ^survey_id,
      group_by: :state,
      select: {r.state, count("*")}) |> Enum.into(%{})

    by_date = Repo.all(
      from r in Respondent, where: r.survey_id == ^survey_id and r.state == "completed",
      group_by: fragment("DATE(completed_at)"),
      select: {fragment("DATE(completed_at)"), count("*")})

    total_respondents = survey |> assoc(:respondents) |> Repo.aggregate(:count, :id)
    range = Timex.Interval.new(from: survey.started_at, until: Timex.now)
    respondents_by_date = Enum.map(range, fn datetime -> responded_on(Timex.to_erl(datetime), by_date) end)

    active = by_state["active"] || 0
    pending = by_state["pending"] || 0
    completed = by_state["completed"] || 0
    stalled = by_state["stalled"] || 0
    failed = by_state["failed"] || 0

    stats = %{
      id: survey.id,
      respondents_by_state: %{
        pending: respondent_by_state(pending, total_respondents),
        completed: respondent_by_state(completed, total_respondents),
        active: respondent_by_state(active, total_respondents),
        stalled: respondent_by_state(stalled, total_respondents),
        failed: respondent_by_state(failed, total_respondents)
      },
      respondents_by_date: respondents_by_date,
      cutoff: survey.cutoff,
      total_respondents: total_respondents
    }
    render(conn, "stats.json", stats: stats)
  end

  def quotas_stats(conn,  %{"project_id" => project_id, "survey_id" => survey_id}) do
    survey = conn
    |> load_project(project_id)
    |> assoc(:surveys)
    |> Repo.get!(survey_id)

    quotas_stats(conn, survey, survey.quota_vars)
  end

  defp quotas_stats(conn, _survey, []) do
    render(conn, "quotas_stats.json", stats: [])
  end

  defp quotas_stats(conn, survey, _) do
    # Get all respondents grouped by quota_bucket_id and state
    values = Repo.all(from r in Respondent,
      where: r.survey_id == ^survey.id,
      where: not is_nil(r.quota_bucket_id),
      group_by: [r.quota_bucket_id, r.state],
      select: [r.quota_bucket_id, r.state, count(r.id)])

    # Get all buckets
    buckets = (survey |> Repo.preload(:quota_buckets)).quota_buckets

    stats = buckets |> Enum.map(fn bucket ->
      bucket_values = values |> Enum.filter(fn [id, _, _] -> id == bucket.id end)
      full = bucket_values
      |> Enum.filter(fn [_, state, _] -> state == "completed" end)
      |> Enum.map(fn [_, _, count] -> count end)
      |> Enum.sum
      partials = bucket_values
      |> Enum.filter(fn [_, state, _] -> state == "active" end)
      |> Enum.map(fn [_, _, count] -> count end)
      |> Enum.sum

      %{
        condition: bucket.condition,
        count: bucket.count,
        quota: bucket.quota,
        full: full,
        partials: partials,
      }
    end)

    render(conn, "quotas_stats.json", stats: stats)
  end

  defp respondent_by_state(count, total_respondents) do
    percent = case total_respondents do
      0 -> 0
      _ -> count / (total_respondents / 100)
    end

    %{count: count, percent: percent}
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

    # If we didn't find a delimiter it probably means
    # there's just a single line in the file.
    # In that case any delimiter, like "\n", is good.
    delimiter = case delimiter do
      -1 -> "\n"
      _  -> delimiter
    end

    csv_string
    |> String.split(delimiter)
    |> Enum.filter(fn r ->
      length = r |> String.trim |> String.split(",") |> Enum.at(0) |> String.length
      length != 0
    end)
    |> Enum.map(fn r ->
      r |> String.trim |> String.split(",") |> Enum.at(0)
    end)
  end

  def render_respondents(conn, survey_id, rows, project) do
    {:ok, local_time } = Ecto.DateTime.cast :calendar.local_time()
    {survey_id, _ } = Integer.parse survey_id

    # For now, create a single respondent group for the survey,
    # so we check if there's already one
    group = RespondentGroup |> Repo.get_by(survey_id: survey_id)
    group = group || (%RespondentGroup{name: "Group", survey_id: survey_id} |> Repo.insert!)

    entries = rows
      |> Enum.map(fn row ->
        %{phone_number: row, sanitized_phone_number: Respondent.sanitize_phone_number(row), survey_id: survey_id, respondent_group_id: group.id, inserted_at: local_time, updated_at: local_time}
      end)

    respondents_count = entries
    |> Enum.chunk(1_000, 1_000, [])
    |> Enum.reduce(0, fn(chunked_entries, total_count)  ->
        {count, _ } = Repo.insert_all(Respondent, chunked_entries)
        total_count + count
      end)

    respondents = mask_phone_numbers(Repo.all(from r in Respondent, where: r.survey_id == ^survey_id, limit: 5))

    update_survey_state(survey_id, respondents_count)
    project |> Project.touch!

    conn
      |> put_status(:created)
      |> render("index.json", respondents: respondents |> Repo.preload(:responses), respondents_count: respondents_count)
  end

  def render_unprocessable_entity(conn) do
    conn
      |> put_status(:unprocessable_entity)
      |> render(Ask.ChangesetView, "error.json", changeset: change(%Respondent{}, %{}))
  end

  def render_invalid(conn, filename, invalid_entries) do
    conn
      |> put_status(:unprocessable_entity)
      |> render("invalid_entries.json", %{invalid_entries: invalid_entries, filename: filename})
  end

  def create(conn, %{"project_id" => project_id, "file" => file, "survey_id" => survey_id}) do
    project = conn
    |> load_project_for_change(project_id)

    if Path.extname(file.filename) == ".csv" do
      rows =
        file.path
        |> File.read!
        |> csv_rows
        |> Enum.uniq

      invalid_entries = rows
      |> Enum.with_index
      |> Enum.map( fn {row, index} -> %{phone_number: row, line_number: index + 1} end)
      |> Enum.filter(fn entry -> !Regex.match?(~r/^([0-9]|\(|\)|\+|\-| )+$/, entry.phone_number) end)

      case invalid_entries do
        [] -> render_respondents(conn, survey_id, rows, project)
        _ -> render_invalid(conn, file.filename, invalid_entries)
      end
    else
      render_unprocessable_entity(conn)
    end
  end

  def delete(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    project = conn
    |> load_project_for_change(project_id)

    # Check that the survey is in the project
    project
    |> assoc(:surveys)
    |> Repo.get!(survey_id)

    from(r in Respondent, where: r.survey_id == ^survey_id)
    |> Repo.delete_all

    # For now remove the only group that all respondents are associated to
    from(g in RespondentGroup, where: g.survey_id == ^survey_id)
    |> Repo.delete_all

    update_survey_state(survey_id, 0)
    project |> Project.touch!

    conn
      |> put_status(:ok)
      |> render("empty.json", respondent: [])
  end

  def csv(conn, %{"project_id" => project_id, "survey_id" => survey_id, "offset" => offset}) do
    project = conn
    |> load_project(project_id)

    # Check that the survey is in the project
    survey = project
    |> assoc(:surveys)
    |> Repo.get!(survey_id)

    questionnaires = (survey |> Repo.preload(:questionnaires)).questionnaires
    has_comparisons = length(survey.comparisons) > 0

    {offset, ""} = Integer.parse(offset)

    # We first need to get all unique field names in all responses
    all_fields = Repo.all(from resp in Response,
      join: r in Respondent,
      where: resp.respondent_id == r.id and
             r.survey_id == ^survey_id and
             resp.field_name != "",
      select: resp.field_name,
      distinct: true)

    # Now traverse each respondent and create a row for it
    csv_rows = from(
      r in Respondent,
      where: r.survey_id == ^survey_id)
    |> preload(:responses)
    |> Repo.stream
    |> Stream.map(fn respondent ->
        row = [respondent.id]
        responses = respondent.responses

        # We traverse all fields and see if there's a response for this respondent
        row = all_fields |> Enum.reduce(row, fn field_name, acc ->
          response = responses
          |> Enum.filter(fn response -> response.field_name == field_name end)
          case response do
            [resp] -> acc ++ [resp.value]
            _ -> acc ++ [""]
          end
        end)

        questionnaire_id = respondent.questionnaire_id
        mode = respondent.mode

        row = if has_comparisons do
          variant = if questionnaire_id && mode do
            questionnaire = questionnaires |> Enum.find(fn q -> q.id == questionnaire_id end)
            if questionnaire do
              "#{questionnaire_name(questionnaire)} - #{mode_label(mode)}"
            else
              "-"
            end
          else
            "-"
          end
          row ++ [variant]
        else
          row
        end

        date = case responses do
          [] -> nil
          _ -> responses
               |> Enum.map(fn r -> r.updated_at end)
               |> Enum.max
               |> Ecto.DateTime.to_erl
               |> Timex.Ecto.DateTime.cast!
               |> Timex.shift(minutes: -offset)
        end

        if date do
          row ++ [date |> Timex.format!("%b %e, %Y %H:%M", :strftime)]
        else
          row ++ ["-"]
        end
    end)

    # Add header to csv_rows
    header = ["Respondent ID"]
    header = header ++ all_fields
    header = if has_comparisons do
      header ++ ["Variant"]
    else
      header
    end
    header = header ++ ["Date"]
    rows = Stream.concat([[header], csv_rows])

    # # Convert to CSV string
    csv = rows
    |> CSV.encode
    |> Enum.to_list
    |> to_string

    filename = Timex.now |> Timex.format!("respondents_%Y-%m-%d-%H-%M-%S.csv", :strftime)

    conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
      |> send_resp(200, csv)
  end

  defp update_survey_state(survey_id, respondents_count) do
    survey = Repo.get!(Survey, survey_id)
    survey = Map.merge(survey, %{respondents_count: respondents_count})

    survey
    |> Repo.preload([:channels, :questionnaires])
    |> change
    |> Survey.update_state
    |> Repo.update
  end

  defp mask_phone_numbers(respondents) do
    masked = respondents
    |>
    Enum.map(fn respondent ->
      %{respondent | phone_number: Respondent.mask_phone_number(respondent.phone_number)}
    end)
    masked
  end

  defp questionnaire_name(quiz) do
    quiz.name || "Untitled questionnaire"
  end

  defp mode_label(mode) do
    case mode do
      ["sms"] -> "SMS"
      ["ivr"] -> "Phone call"
      ["ivr", "sms"] -> "Phone call with SMS fallback"
      ["sms", "ivr"] -> "SMS with phone call fallback"
      _ -> "Unknown mode"
    end
  end
end
