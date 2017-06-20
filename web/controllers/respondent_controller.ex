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

    stats(conn, survey, survey.quota_vars)
  end

  defp stats(conn, survey, []) do
    questionnaires = (survey |> Repo.preload(:questionnaires)).questionnaires
    if length(questionnaires) > 1 && length(survey.mode) > 1 do
      reference = questionnaires
      |> Enum.reduce([], fn(questionnaire, reference) ->
        survey.mode
        |> Enum.reduce(reference, fn(modes, reference) ->
          reference ++ [%{
            id: "#{questionnaire.id}#{modes |> Enum.join("")}",
            name: questionnaire.name,
            modes: modes
          }]
        end)
      end)

      stats(
        conn,
        survey,
        survey |> assoc(:respondents) |> Repo.aggregate(:count, :id),
        respondents_by_questionnaire_mode_and_disposition(survey),
        respondents_by_questionnaire_mode_and_completed_at(survey),
        reference,
        [],
        "stats.json"
      )
    else
      if length(survey.mode) > 1 do
        reference = survey.mode
        |> Enum.map(fn(modes) ->
          %{
            id: modes |> Enum.join(""),
            modes: modes
          }
        end)

        stats(
          conn,
          survey,
          survey |> assoc(:respondents) |> Repo.aggregate(:count, :id),
          respondents_by_mode_and_disposition(survey),
          respondents_by_mode_and_completed_at(survey),
          reference,
          [],
          "stats.json"
        )
      else
        reference = questionnaires
        |> Enum.map(fn q ->
          %{id: q.id, name: q.name}
        end)

        stats(
          conn,
          survey,
          survey |> assoc(:respondents) |> Repo.aggregate(:count, :id),
          respondents_by_questionnaire_and_disposition(survey),
          respondents_by_questionnaire_and_completed_at(survey),
          reference,
          [],
          "stats.json"
        )
      end
    end
  end

  defp stats(conn, survey, _) do
    buckets = (survey |> Repo.preload(:quota_buckets)).quota_buckets

    stats(
      conn,
      survey,
      survey |> assoc(:respondents) |> Repo.aggregate(:count, :id),
      respondents_by_bucket_and_disposition(survey),
      respondents_by_quota_bucket_and_completed_at(survey),
      buckets,
      buckets,
      "quotas_stats.json"
    )
  end

  defp stats(conn, survey, total_respondents, respondents_by_disposition, respondents_by_completed_at, reference, buckets, layout) do

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

    # Completion percentage
    pending_respondents =
      Repo.one(
        from r in Respondent,
        where: r.survey_id == ^survey.id and r.state == "pending",
        select: count("*")
      )
    completed_or_partial =
      Repo.one(
        from r in Respondent,
        where: r.survey_id == ^survey.id and r.disposition in ["completed", "partial"],
        select: count("*")
      )
    completion_percentage = (completed_or_partial / target) * 100

    stats = %{
      id: survey.id,
      reference: reference,
      respondents_by_disposition: respondent_counts(respondents_by_disposition, total_respondents),
      cumulative_percentages: cumulative_percentages(respondents_by_completed_at, survey, target),
      completion_percentage: completion_percentage,
      total_respondents: total_respondents,
      contacted_respondents: total_respondents - pending_respondents
    }

    render(conn, layout, stats: stats)
  end

  defp respondent_counts(grouped_responents, total_respondents) do
    respondent_counts =
      grouped_responents
      |> Enum.reduce(%{}, fn {state, disposition, reference_id, count}, counts ->
        disposition = disposition || state

        default_for_disposition = %{disposition => %{by_reference: %{}, count: 0}}
        counts = default_for_disposition |> Map.merge(counts)

        default_for_quota_bucket = %{to_string(reference_id) => count}
        by_reference =
          default_for_quota_bucket
          |> Map.merge(counts[disposition][:by_reference], fn (_, count, current_count) ->
            count + current_count
          end)

        disposition_total_count = counts[disposition][:count] + count

        counts |> Map.put(disposition, %{by_reference: by_reference, count: disposition_total_count})
      end)
    dispositions = ["registered", "queued", "failed", "contacted", "unresponsive", "started", "ineligible", "rejected", "breakoff", "refused", "partial", "completed"]
    respondent_counts =
      dispositions
      |> Enum.reduce(respondent_counts, fn (disposition, respondent_counts) ->
          respondent_counts |> Map.put_new(disposition, %{
            by_reference: %{},
            count: 0
          })
        end)

    respondent_counts = add_disposition_percent(respondent_counts, total_respondents)

    groups = %{
      uncontacted: ["registered", "queued", "failed"],
      contacted: ["contacted", "unresponsive"],
      responsive: ["started", "ineligible", "rejected", "breakoff", "refused", "partial", "completed"]
    }

    groups
    |> Enum.map(fn {name, dispositions} ->
        {count, percent, detail} =
          dispositions
          |> Enum.reduce({0, 0, %{}}, fn disposition, {count_sum, percent_sum, detail} ->
              {respondent_counts[disposition][:count] + count_sum, respondent_counts[disposition][:percent] + percent_sum, Map.put(detail, disposition, respondent_counts[disposition])}
            end)
        {name, %{ count: count, percent: percent, detail: detail }}
      end)
    |> Enum.into(%{})
  end

  defp cumulative_percentages(grouped_respondents, survey, target) do
    # Cumulative percentages by bucket by date
    # TODO We are only displaying completed in the chart because we don't store the partial_at date yet.

    range =
      Timex.Interval.new(from: survey.started_at, until: Timex.now)
      |> Enum.map(fn datetime ->
        { date, _ } = Timex.to_erl(datetime)
        date
      end)

    grouped_respondents
      |> Enum.reduce(%{}, fn {group_id, date, count}, acc ->
          {_, next_acc} =
            acc
            |> Map.put_new(group_id, [])
            |> Map.get_and_update(group_id, fn date_percent ->
                {date_percent, date_percent ++ [{date, (count / target) * 100}]} # TODO This should be the corresponding bucket quota
              end)
          next_acc
        end)
      |> Enum.map(fn {group_id, percents_by_date} ->
          {group_id, cumulative_percent_for(range, percents_by_date)}
        end)
      |> Enum.into(%{})
  end

  defp respondents_by_questionnaire_and_disposition(survey) do
    Repo.all(
      from r in Respondent, where: r.survey_id == ^survey.id,
      group_by: [:state, :disposition, :questionnaire_id],
      select: {r.state, r.disposition, r.questionnaire_id, count("*")})
  end

  defp respondents_by_questionnaire_mode_and_disposition(survey) do
    Repo.all(
      from r in Respondent, where: r.survey_id == ^survey.id,
      group_by: [:state, :disposition, :questionnaire_id, :mode],
      select: {r.state, r.disposition, r.questionnaire_id, r.mode, count("*")})
    |> Enum.map(fn({state, disposition, questionnaire_id, mode, count}) ->
      reference_id = if mode && questionnaire_id do
        "#{questionnaire_id}#{mode |> Enum.join("")}"
      else
        nil
      end

      {state, disposition, reference_id, count}
    end)
  end

  defp respondents_by_mode_and_disposition(survey) do
    Repo.all(
      from r in Respondent, where: r.survey_id == ^survey.id,
      group_by: [:state, :disposition, :mode],
      select: {r.state, r.disposition, r.mode, count("*")})
  end

  defp respondents_by_bucket_and_disposition(survey) do
    Repo.all(
      from r in Respondent, where: r.survey_id == ^survey.id,
      group_by: [:state, :disposition, :quota_bucket_id],
      select: {r.state, r.disposition, r.quota_bucket_id, count("*")})
  end

  defp respondents_by_questionnaire_and_completed_at(survey) do
    Repo.all(
      from r in Respondent, where: r.survey_id == ^survey.id and r.disposition == "completed",
      group_by: fragment("questionnaire_id, DATE(completed_at)"),
      order_by: fragment("DATE(completed_at) ASC"),
      select: {r.questionnaire_id, fragment("DATE(completed_at)"), count("*")})
  end

  defp respondents_by_questionnaire_mode_and_completed_at(survey) do
    Repo.all(
      from r in Respondent, where: r.survey_id == ^survey.id and r.disposition == "completed",
      group_by: fragment("questionnaire_id, mode, DATE(completed_at)"),
      order_by: fragment("DATE(completed_at) ASC"),
      select: {r.questionnaire_id, r.mode, fragment("DATE(completed_at)"), count("*")})
    |> Enum.map(fn({questionnaire_id, mode, completed_at, count}) ->
      reference_id = if mode && questionnaire_id do
        "#{questionnaire_id}#{mode |> Enum.join("")}"
      else
        nil
      end

      {reference_id, completed_at, count}
    end)
  end

  defp respondents_by_mode_and_completed_at(survey) do
    Repo.all(
      from r in Respondent, where: r.survey_id == ^survey.id and r.disposition == "completed",
      group_by: fragment("mode, DATE(completed_at)"),
      order_by: fragment("DATE(completed_at) ASC"),
      select: {r.mode, fragment("DATE(completed_at)"), count("*")})
  end

  defp respondents_by_quota_bucket_and_completed_at(survey) do
    Repo.all(
      from r in Respondent, where: r.survey_id == ^survey.id and r.disposition == "completed",
      group_by: fragment("quota_bucket_id, DATE(completed_at)"),
      order_by: fragment("DATE(completed_at) ASC"),
      select: {r.quota_bucket_id, fragment("DATE(completed_at)"), count("*")})
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

  def csv(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    project = conn
    |> load_project(project_id)

    # Check that the survey is in the project
    survey = project
    |> assoc(:surveys)
    |> Repo.get!(survey_id)

    tz_offset = Survey.timezone_offset(survey)

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
      where: r.survey_id == ^survey_id,
      order_by: r.id)
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
          row ++ [date |> Timex.format!("%b %e, %Y %H:%M #{tz_offset}", :strftime)]
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

    filename = csv_filename(survey, "respondents")
    conn |> csv_stream(rows, filename)
  end

  def disposition_history_csv(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    project = conn
    |> load_project(project_id)

    # Check that the survey is in the project
    survey = project
    |> assoc(:surveys)
    |> Repo.get!(survey_id)

    tz_offset = Survey.timezone_offset(survey)
    csv_rows = (from h in RespondentDispositionHistory,
      join: r in Respondent,
      where: h.respondent_id == r.id and r.survey_id == ^survey.id,
      order_by: h.id)
    |> preload(:respondent)
    |> Repo.stream
    |> Stream.map(fn history ->
      date = history.inserted_at
      |> Survey.adjust_timezone(survey)
      |> Timex.format!("%Y-%m-%d %H:%M:%S #{tz_offset}", :strftime)
      [history.respondent.hashed_number, history.disposition, mode_label([history.mode]), date]
    end)

    header = ["Respondent ID", "Disposition", "Mode", "Timestamp"]
    rows = Stream.concat([[header], csv_rows])

    filename = csv_filename(survey, "respondents_disposition_history")
    conn |> csv_stream(rows, filename)
  end

  def incentives_csv(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    project = conn
    |> load_project_for_owner(project_id)

    # Check that the survey is in the project
    survey = project
    |> assoc(:surveys)
    |> Repo.get!(survey_id)

    csv_rows = (from r in Respondent,
      where: r.survey_id == ^survey.id and r.disposition == "completed" and not is_nil(r.questionnaire_id),
      order_by: r.id)
    |> preload(:questionnaire)
    |> Repo.stream
    |> Stream.map(fn r ->
      [r.phone_number, experiment_name(r.questionnaire, r.mode)]
    end)

    header = ["Telephone number", "Questionnaire-Mode"]
    rows = Stream.concat([[header], csv_rows])

    filename = csv_filename(survey, "respondents_incentives")
    conn |> csv_stream(rows, filename)
  end

  def interactions_csv(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    project = conn
    |> load_project_for_owner(project_id)

    # Check that the survey is in the project
    survey = project
    |> assoc(:surveys)
    |> Repo.get!(survey_id)

    log_stream = Stream.resource(fn -> {"", 0} end,
      fn {last_seen_respondent_hashed_number, last_seen_id} ->
        results =
          (from e in SurveyLogEntry,
          where: e.survey_id == ^survey.id and (
            (e.respondent_hashed_number == ^last_seen_respondent_hashed_number and e.id > ^last_seen_id) or
            (e.respondent_hashed_number > ^last_seen_respondent_hashed_number)),
          order_by: [e.respondent_hashed_number, e.id])
          |> preload(:channel)
          |> limit(500)
          |> Repo.all

        case List.last(results) do
          %{respondent_hashed_number: last_respondent_hashed_number, id: last_id} ->
            {results, {last_respondent_hashed_number, last_id}}
          nil ->
            {:halt, nil}
        end
      end,
      fn _ -> [] end)

    tz_offset = Survey.timezone_offset(survey)

    csv_rows = log_stream
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
      |> Timex.format!("%Y-%m-%d %H:%M:%S #{tz_offset}", :strftime)

      [e.respondent_hashed_number, interactions_mode_label(e.mode), channel_name, disposition, action_type, e.action_data, timestamp]
    end)

    header = ["Respondent ID", "Mode", "Channel", "Disposition", "Action Type", "Action Data", "Timestamp"]
    rows = Stream.concat([[header], csv_rows])

    filename = csv_filename(survey, "respondents_interactions")
    conn |> csv_stream(rows, filename)
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
