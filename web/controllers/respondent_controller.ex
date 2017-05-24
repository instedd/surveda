defmodule Ask.RespondentController do
  use Ask.Web, :api_controller

  alias Ask.{Respondent, RespondentDispositionHistory, Questionnaire, Survey, SurveyLogEntry}

  def index(conn, %{"project_id" => project_id, "survey_id" => survey_id} = params) do
    limit = Map.get(params, "limit", "")
    page = Map.get(params, "page", "")
    sort_by = Map.get(params, "sort_by", "")
    sort_asc = Map.get(params, "sort_asc", "")

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
    |> sort_respondents(sort_by, sort_asc)
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

  defp sort_respondents(query, sort_by, sort_asc) do
    case {sort_by, sort_asc} do
      {"phoneNumber", "true"} ->
        query |> order_by([r], asc: r.hashed_number)
      {"phoneNumber", "false"} ->
        query |> order_by([r], desc: r.hashed_number)
      {"date", "true"} ->
        query |> order_by([r], asc: r.updated_at)
      {"date", "false"} ->
        query |> order_by([r], desc: r.updated_at)
      _ ->
        query
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

  def stats(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    survey = conn
    |> load_project(project_id)
    |> assoc(:surveys)
    |> Repo.get!(survey_id)

    by_disposition = Repo.all(
      from r in Respondent, where: r.survey_id == ^survey_id,
      group_by: [:disposition],
      select: {r.disposition, count("*")})
    |> Enum.reduce(%{}, fn {disposition, count}, map ->
      key = disposition
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

    registered = by_disposition["registered"] || 0
    queued = by_disposition["queued"] || 0
    contacted = by_disposition["contacted"] || 0
    failed = by_disposition["failed"] || 0
    unresponsive = by_disposition["unresponsive"] || 0
    started = by_disposition["started"] || 0
    ineligible = by_disposition["ineligible"] || 0
    rejected = by_disposition["rejected"] || 0
    breakoff = by_disposition["breakoff"] || 0
    refused = by_disposition["refused"] || 0
    partial = by_disposition["partial"] || 0
    completed = by_disposition["completed"] || 0
    responsive = started + ineligible + rejected + breakoff + refused + partial + completed
    contacted_group = contacted + unresponsive
    uncontacted = registered + queued + failed

    total_quota = buckets
    |> Enum.reduce(0, fn bucket, total ->
      total + (bucket.quota || 0)
    end)

    stats = %{
      id: survey.id,
      respondents_by_disposition: %{
        uncontacted: %{
          count: uncontacted,
          percent: respondent_percentage(uncontacted, total_respondents),
          detail: %{
            registered: %{count: registered, percent: respondent_percentage(registered, total_respondents)},
            queued: %{count: queued, percent: respondent_percentage(queued, total_respondents)},
            failed: %{count: failed, percent: respondent_percentage(failed, total_respondents)},
          },
        },
        contacted: %{
          count: contacted_group,
          percent: respondent_percentage(contacted_group, total_respondents),
          detail: %{
            contacted: %{count: contacted, percent: respondent_percentage(contacted, total_respondents)},
            unresponsive: %{count: unresponsive, percent: respondent_percentage(unresponsive, total_respondents)},
          },
        },
        responsive: %{
          count: responsive,
          percent: respondent_percentage(responsive, total_respondents),
          detail: %{
            started: %{count: started, percent: respondent_percentage(started, total_respondents)},
            ineligible: %{count: ineligible, percent: respondent_percentage(ineligible, total_respondents)},
            rejected: %{count: rejected, percent: respondent_percentage(rejected, total_respondents)},
            breakoff: %{count: breakoff, percent: respondent_percentage(breakoff, total_respondents)},
            refused: %{count: refused, percent: respondent_percentage(refused, total_respondents)},
            partial: %{count: partial, percent: respondent_percentage(partial, total_respondents)},
            completed: %{count: completed, percent: respondent_percentage(completed, total_respondents)},
          },
        },
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

  defp respondent_percentage(_, 0), do: 0
  defp respondent_percentage(count, total_respondents), do: count / (total_respondents / 100)

  def csv(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    project = conn
    |> load_project(project_id)

    # Check that the survey is in the project
    survey = project
    |> assoc(:surveys)
    |> Repo.get!(survey_id)

    questionnaires = (survey |> Repo.preload(:questionnaires)).questionnaires
    has_comparisons = length(survey.comparisons) > 0

    # We first need to get all unique field names in all questionnaires
    all_fields = questionnaires
    |> Enum.flat_map(&Questionnaire.variables/1)
    |> Enum.map(fn s -> String.trim(s) end)
    |> Enum.uniq
    |> Enum.reject(fn s -> String.length(s) == 0 end)

    # Now traverse each respondent and create a row for it
    csv_rows = from(
      r in Respondent,
      where: r.survey_id == ^survey_id)
    |> preload(:responses)
    |> Repo.stream
    |> Stream.map(fn respondent ->
        row = [respondent.hashed_number]
        responses = respondent.responses

        date = case responses do
          [] -> nil
          _ -> responses
               |> Enum.map(fn r -> r.updated_at end)
               |> Enum.max
               |> Survey.adjust_timezone(survey)
        end

        row = if date do
          row ++ [date |> Timex.format!("%b %e, %Y %H:%M #{Survey.timezone_offset(survey)}", :strftime)]
        else
          row ++ ["-"]
        end

        modes = (respondent.effective_modes || [])
        |> Enum.map(fn mode -> mode_label([mode]) end)
        |> Enum.join(", ")

        row = row ++ [modes]

        # We traverse all fields and see if there's a response for this respondent
        row = all_fields |> Enum.reduce(row, fn field_name, acc ->
          response = responses
          |> Enum.filter(fn response -> response.field_name == field_name end)
          case response do
            [resp] ->
              value = resp.value

              # For the 'language' variable we convert the code to the native name
              value = if resp.field_name == "language" do
                LanguageNames.for(value) || value
              else
                value
              end

              acc ++ [value]
            _ ->
              acc ++ [""]
          end
        end)

        questionnaire_id = respondent.questionnaire_id
        mode = respondent.mode

        row = if has_comparisons do
          variant = if questionnaire_id && mode do
            questionnaire = questionnaires |> Enum.find(fn q -> q.id == questionnaire_id end)
            if questionnaire do
              experiment_name(questionnaire, mode)
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

        row
    end)

    # Add header to csv_rows
    header = ["Respondent ID", "Date", "Modes"]
    header = header ++ all_fields
    header = if has_comparisons do
      header ++ ["Variant"]
    else
      header
    end
    header = header ++ ["Disposition"]
    rows = Stream.concat([[header], csv_rows])

    # # Convert to CSV string
    csv = rows
    |> CSV.encode
    |> Enum.to_list
    |> to_string

    filename = csv_filename(survey, "respondents")

    conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
      |> send_resp(200, csv)
  end

  def disposition_history_csv(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    project = conn
    |> load_project(project_id)

    # Check that the survey is in the project
    survey = project
    |> assoc(:surveys)
    |> Repo.get!(survey_id)

    csv_rows = (from h in RespondentDispositionHistory,
      join: r in Respondent,
      where: h.respondent_id == r.id and r.survey_id == ^survey.id)
    |> preload(:respondent)
    |> Repo.stream
    |> Stream.map(fn history ->
      date = history.inserted_at
      |> Survey.adjust_timezone(survey)
      |> Timex.format!("%Y-%m-%d %H:%M:%S #{Survey.timezone_offset(survey)}", :strftime)
      [history.respondent.hashed_number, history.disposition, mode_label([history.mode]), date]
    end)

    header = ["Respondent ID", "Disposition", "Mode", "Timestamp"]
    rows = Stream.concat([[header], csv_rows])

    # Convert to CSV string
    csv = rows
    |> CSV.encode
    |> Enum.to_list
    |> to_string

    filename = csv_filename(survey, "respondents_disposition_history")

    conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
      |> send_resp(200, csv)
  end

  def incentives_csv(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    project = conn
    |> load_project_for_owner(project_id)

    # Check that the survey is in the project
    survey = project
    |> assoc(:surveys)
    |> Repo.get!(survey_id)

    csv_rows = (from r in Respondent,
      where: r.survey_id == ^survey.id and r.disposition == "completed" and not is_nil(r.questionnaire_id))
    |> preload(:questionnaire)
    |> Repo.stream
    |> Stream.map(fn r ->
      [r.phone_number, experiment_name(r.questionnaire, r.mode)]
    end)

    header = ["Telephone number", "Questionnaire-Mode"]
    rows = Stream.concat([[header], csv_rows])

    # Convert to CSV string
    csv = rows
    |> CSV.encode
    |> Enum.to_list
    |> to_string

    filename = csv_filename(survey, "respondents_incentives")

    conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
      |> send_resp(200, csv)
  end

  def interactions_csv(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    project = conn
    |> load_project_for_owner(project_id)

    # Check that the survey is in the project
    survey = project
    |> assoc(:surveys)
    |> Repo.get!(survey_id)

    csv_rows = (from e in SurveyLogEntry,
      where: e.survey_id == ^survey.id,
      order_by: [e.respondent_hashed_number])
    |> preload(:channel)
    |> Repo.stream
    |> Stream.map(fn e ->
      channel_name =
        if e.channel do
          e.channel.name
        else
          ""
        end

      disposition = disposition_label(e.disposition)
      action_type = action_type_label(e.action_type)

      timestamp = e.timestamp
      |> Survey.adjust_timezone(survey)
      |> Timex.format!("%Y-%m-%d %H:%M:%S #{Survey.timezone_offset(survey)}", :strftime)

      [e.respondent_hashed_number, interactions_mode_label(e.mode), channel_name, disposition, action_type, e.action_data, timestamp]
    end)

    header = ["Respondent ID", "Mode", "Channel", "Disposition", "Action Type", "Action Data", "Timestamp"]
    rows = Stream.concat([[header], csv_rows])

    # Convert to CSV string
    csv = rows
    |> CSV.encode
    |> Enum.to_list
    |> to_string

    filename = csv_filename(survey, "respondents_interactions")

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

  defp experiment_name(quiz, mode) do
    "#{questionnaire_name(quiz)} - #{mode_label(mode)}"
  end

  defp questionnaire_name(quiz) do
    quiz.name || "Untitled questionnaire"
  end

  defp mode_label(mode) do
    case mode do
      ["sms"] -> "SMS"
      ["sms", "ivr"] -> "SMS with phone call fallback"
      ["sms", "mobileweb"] -> "SMS with Mobile Web fallback"
      ["ivr"] -> "Phone call"
      ["ivr", "sms"] -> "Phone call with SMS fallback"
      ["ivr", "mobileweb"] -> "Phone call with Mobile Web fallback"
      ["mobileweb"] -> "Mobile Web"
      ["mobileweb", "sms"] -> "Mobile Web with SMS fallback"
      ["mobileweb", "ivr"] -> "Mobile Web with phone call fallback"
      _ -> "Unknown mode"
    end
  end

  defp interactions_mode_label(mode) do
    case mode do
      "mobileweb" -> "Mobile Web"
      _ -> String.upcase(mode)
    end
  end

  defp action_type_label(action) do
    case action do
      nil -> nil
      "contact" -> "Contact attempt"
      _ -> String.capitalize(action)
    end
  end

  defp disposition_label(disposition) do
    case disposition do
      nil -> nil
      _ -> String.capitalize(disposition)
    end
  end

  defp csv_filename(survey, prefix) do
    name = survey.name || "survey_id_#{survey.id}"
    name = Regex.replace(~r/[^a-zA-Z0-9_]/, name, "_")
    prefix = "#{name}-#{prefix}"
    Timex.format!(Timex.now, "#{prefix}_%Y-%m-%d-%H-%M-%S.csv", :strftime)
  end
end
