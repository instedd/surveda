defmodule Ask.RespondentController do
  use Ask.Web, :api_controller

  alias Ask.{Respondent, Response}

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
    |> mask_phone_numbers

    render(conn, "index.json", respondents: respondents, respondents_count: respondents_count)
  end

  defp conditional_limit query, limit do
    case limit do
      "" -> query
      number -> query |> limit(^number)
    end
  end

  defp conditional_page query, limit, page do
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

  def responded_on(date, by_date) do
    value = Enum.filter(by_date, fn x -> elem(x, 0) == date end)
    {date, value}
  end

  def cumulative_count_for(date, by_date, buckets) do
    value = if buckets |> length == 0 do
      by_date
      |> Enum.reduce(0, fn respondents_by_date, total ->
        if(elem(respondents_by_date, 0) <= date) do
          case elem(respondents_by_date, 1) do
            [] -> total
            [{_, _, count}] -> total + count
          end
        else
          total
        end
      end)
    else
      buckets = buckets |> Enum.map(fn bucket ->
        {bucket.id, 0, bucket.quota || 0}
      end)
      by_date
      |> Enum.reduce(buckets, fn respondents_by_date, buckets ->
        {respondents_date, respondents} = respondents_by_date
        if(respondents_date <= date) do
          respondents |> Enum.reduce(buckets, fn respondent, buckets ->
            {_, bucket_id, count} = respondent
            bucket = buckets |> Enum.find(fn bucket -> elem(bucket, 0) == bucket_id end)
            case bucket do
              nil -> buckets
              {bucket_id, total, quota} ->
                (buckets -- [bucket]) ++ [{
                  bucket_id,
                  min(quota, total + count),
                  quota
                }]
            end
          end)
        else
          buckets
        end
      end)
      |> Enum.reduce(0, fn bucket, total ->
        total + elem(bucket, 1)
      end)
    end
    {date, value}
  end

  def stats(conn,  %{"project_id" => project_id, "survey_id" => survey_id}) do
    survey = conn
    |> load_project(project_id)
    |> assoc(:surveys)
    |> Repo.get!(survey_id)

    by_state = Repo.all(
      from r in Respondent, where: r.survey_id == ^survey_id,
      group_by: [:state, :disposition],
      select: {r.state, r.disposition, count("*")})
    |> Enum.reduce(%{}, fn {state, disposition, count}, map ->
      key = disposition || state
      map |> Map.put(key, (map[key] || 0) + count)
    end)

    by_date = Repo.all(
      from r in Respondent, where: r.survey_id == ^survey_id and r.disposition == "completed",
      group_by: fragment("DATE(completed_at), quota_bucket_id"),
      select: {fragment("DATE(completed_at)"), r.quota_bucket_id, count("*")})

    total_respondents = survey |> assoc(:respondents) |> Repo.aggregate(:count, :id)

    buckets = (survey |> Repo.preload(:quota_buckets)).quota_buckets

    range =
      Timex.Interval.new(from: survey.started_at, until: Timex.now)
      |> Enum.map(fn datetime ->
        { date, _ } = Timex.to_erl(datetime)
        date
      end)
    respondents_by_date = Enum.map(range, fn datetime -> responded_on(datetime, by_date) end)

    cumulative_count = Enum.map(range, fn datetime -> cumulative_count_for(datetime, respondents_by_date, buckets) end)

    active = by_state["active"] || 0
    pending = by_state["pending"] || 0
    completed = by_state["completed"] || 0
    stalled = by_state["stalled"] || 0
    failed = by_state["failed"] || 0
    partial = by_state["partial"] || 0
    ineligible = by_state["ineligible"] || 0

    total_quota = buckets
    |> Enum.reduce(0, fn bucket, total ->
      total + (bucket.quota || 0)
    end)

    stats = %{
      id: survey.id,
      respondents_by_state: %{
        pending: respondent_by_state(pending, total_respondents),
        completed: respondent_by_state(completed, total_respondents),
        active: respondent_by_state(active, total_respondents),
        stalled: respondent_by_state(stalled, total_respondents),
        failed: respondent_by_state(failed, total_respondents),
        partial: respondent_by_state(partial, total_respondents),
        ineligible: respondent_by_state(ineligible, total_respondents),
      },
      respondents_by_date: cumulative_count,
      cutoff: survey.cutoff,
      total_quota: total_quota,
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
        row = [respondent.hashed_number]
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

        row = row ++ [Respondent.show_disposition(respondent.disposition)]

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
    header = header ++ ["Disposition", "Date"]
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

  defp mask_phone_numbers(respondents) do
    respondents |> Enum.map(fn respondent ->
      %{respondent | phone_number: Respondent.mask_phone_number(respondent.phone_number)}
    end)
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
