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

  defp cumulative_percent_for(range, percent_by_date) do
    range
    |> Enum.reduce({percent_by_date, 0, []}, fn date, acc ->
      {percents_by_date, cumulative_percent, cumulative_percent_by_date} = acc
      case percents_by_date do
        [] ->
          {[], cumulative_percent, cumulative_percent_by_date ++ [{date, cumulative_percent}]}
        [{next_date, next_percent} | rest_percents_by_date] ->
          cond do
            date < next_date ->
              {percents_by_date, cumulative_percent, cumulative_percent_by_date ++ [{date, cumulative_percent}]}
            date == next_date ->
              {rest_percents_by_date, cumulative_percent + next_percent, cumulative_percent_by_date ++ [{date, cumulative_percent + next_percent}]}
          end
      end
    end)
    |> elem(2)
  end

  def stats(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    survey = conn
    |> load_project(project_id)
    |> assoc(:surveys)
    |> Repo.get!(survey_id)

    # Respondents counts by disposition

    respondents_counts =
      Repo.all(
        from r in Respondent, where: r.survey_id == ^survey_id,
        group_by: [:state, :disposition, :questionnaire_id],
        select: {r.state, r.disposition, r.questionnaire_id, count("*")})
      |> Enum.reduce(%{}, fn {state, disposition, questionnaire_id, count}, counts ->
        disposition = disposition || state

        default_for_disposition = %{disposition => %{by_questionnaire: %{}, count: 0}}
        counts = default_for_disposition |> Map.merge(counts)

        default_for_questionnaire = %{to_string(questionnaire_id) => count}
        by_questionnaire =
          default_for_questionnaire
          |> Map.merge(counts[disposition][:by_questionnaire], fn (_, count, current_count) ->
            count + current_count
          end)

        disposition_total_count = counts[disposition][:count] + count

        counts |> Map.put(disposition, %{by_questionnaire: by_questionnaire, count: disposition_total_count})
      end)
    dispositions = ["registered", "queued", "failed", "contacted", "unresponsive", "started", "ineligible", "rejected", "breakoff", "refused", "partial", "completed"]
    respondents_counts =
      dispositions
      |> Enum.reduce(respondents_counts, fn (disposition, respondents_counts) ->
          respondents_counts |> Map.put_new(disposition, %{
            by_questionnaire: %{},
            count: 0
          })
        end)

    total_respondents = survey |> assoc(:respondents) |> Repo.aggregate(:count, :id)
    respondents_counts = add_disposition_percent(respondents_counts, total_respondents)


    groups = %{
      uncontacted: ["registered", "queued", "failed"],
      contacted: ["contacted", "unresponsive"],
      responsive: ["started", "ineligible", "rejected", "breakoff", "refused", "partial", "completed"]
    }

    respondents_counts =
      groups
      |> Enum.map(fn {name, dispositions} ->
          {count, percent, detail} =
            dispositions
            |> Enum.reduce({0, 0, %{}}, fn disposition, {count_sum, percent_sum, detail} ->
                {respondents_counts[disposition][:count] + count_sum, respondents_counts[disposition][:percent] + percent_sum, Map.put(detail, disposition, respondents_counts[disposition])}
              end)
          {name, %{ count: count, percent: percent, detail: detail }}
        end)
      |> Enum.into(%{})

    # Cumulative percentages by questionnaire by date
    buckets = (survey |> Repo.preload(:quota_buckets)).quota_buckets
    total_quota =
      buckets
      |> Enum.reduce(0, fn bucket, total ->
        total + (bucket.quota || 0)
      end)
    target =
      cond do
        total_quota > 0 -> total_quota
        !is_nil(survey.cutoff) -> survey.cutoff
        true -> total_respondents
      end

    range =
      Timex.Interval.new(from: survey.started_at, until: Timex.now)
      |> Enum.map(fn datetime ->
        { date, _ } = Timex.to_erl(datetime)
        date
      end)

    cumulative_percentage_by_questionnaire =
      Repo.all(
        from r in Respondent, where: r.survey_id == ^survey_id and r.disposition == "completed",
        group_by: fragment("questionnaire_id, DATE(completed_at)"),
        order_by: fragment("DATE(completed_at) ASC"),
        select: {r.questionnaire_id, fragment("DATE(completed_at)"), count("*")})
      |> Enum.reduce(%{}, fn {questionnaire_id, date, count}, acc ->
          {_, next_acc} =
            acc
            |> Map.put_new(questionnaire_id, [])
            |> Map.get_and_update(questionnaire_id, fn date_percent ->
                {date_percent, date_percent ++ [{date, (count / target) * 100}]}
              end)
          next_acc
        end)
      |> Enum.map(fn {questionnaire_id, percents_by_date} ->
          {questionnaire_id, cumulative_percent_for(range, percents_by_date)}
        end)
      |> Enum.into(%{})

    # Completion percentage
    pending_respondents =
      Repo.one(
        from r in Respondent,
        where: r.survey_id == ^survey_id and r.state == "pending",
        select: count("*")
      )
    completed_or_partial =
      Repo.one(
        from r in Respondent,
        where: r.survey_id == ^survey_id and r.disposition in ["completed", "partial"],
        select: count("*")
      )
    completion_percentage = (completed_or_partial / target) * 100

    stats = %{
      id: survey.id,
      respondents_by_disposition: respondents_counts,
      cumulative_percentages: cumulative_percentage_by_questionnaire,
      completion_percentage: completion_percentage,
      total_respondents: total_respondents,
      contacted_respondents: total_respondents - pending_respondents
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

  defp add_disposition_percent(respondents_count_by_disposition_and_questionnaire, total_respondents) do
    respondents_count_by_disposition_and_questionnaire
    |> Enum.map(fn {disposition, counts} ->
        percent_of_disposition =
          case total_respondents do
            0 -> 0
            _ -> respondents_count_by_disposition_and_questionnaire[disposition][:count] / (total_respondents / 100)
          end
        counts_with_percent = counts |> Map.put(:percent, percent_of_disposition)
        {disposition, counts_with_percent}
      end)
    |> Enum.into(%{})
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
