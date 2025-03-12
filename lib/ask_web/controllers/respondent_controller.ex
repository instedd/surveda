defmodule AskWeb.RespondentController do
  use AskWeb, :api_controller
  require Ask.RespondentStats

  alias Ask.{
    ActivityLog,
    CompletedRespondents,
    Logger,
    Respondent,
    Survey,
    RespondentsFilter
  }

  alias Ask.SurveyResults

  def index(conn, %{"project_id" => project_id, "survey_id" => survey_id} = params) do
    limit = Map.get(params, "limit", "")
    page = Map.get(params, "page", "")
    sort_by = Map.get(params, "sort_by", "")
    sort_asc = Map.get(params, "sort_asc", "")
    q = Map.get(params, "q", "")

    filter = RespondentsFilter.parse(q)
    filter_where = RespondentsFilter.filter_where(filter)

    filtered_query =
      conn
      |> load_project(project_id)
      |> load_survey(survey_id)
      |> assoc(:respondents)
      |> preload(:responses)
      |> preload(:questionnaire)
      |> where(^filter_where)

    respondents_count = Repo.aggregate(filtered_query, :count, :id)

    respondents =
      filtered_query
      |> conditional_limit(limit)
      |> conditional_page(limit, page)
      |> sort_respondents(sort_by, sort_asc)
      |> Repo.all()
      |> Enum.map(fn respondent ->
        respondent
        |> mask_phone_numbers
        |> effective_stats
      end)

    survey = Repo.get!(Survey, survey_id) |> Repo.preload(:questionnaires)

    partial_relevant_enabled = Survey.partial_relevant_enabled?(survey, true)

    render(conn, "index.json",
      respondents: respondents,
      respondents_count: respondents_count,
      partial_relevant_enabled: partial_relevant_enabled,
      index_fields:
        index_fields_for_render(%{
          survey: survey,
          partial_relevant_enabled: partial_relevant_enabled
        })
    )
  end

  defp index_fields_for_render(%{
         survey: survey,
         partial_relevant_enabled: partial_relevant_enabled
       }),
       do:
         index_fields_for_render("fixed") ++
           index_fields_for_render("mode", survey.mode) ++
           index_fields_for_render("variant", survey.comparisons) ++
           index_fields_for_render("partial_relevant", partial_relevant_enabled) ++
           index_fields_for_render("response", survey.questionnaires)

  defp index_fields_for_render("fixed" = field_type),
    do:
      ["phone_number", "disposition", "date"]
      |> map_fields_with_type(field_type)

  defp index_fields_for_render("mode" = field_type, survey_modes),
    do:
      List.flatten(survey_modes)
      |> Enum.uniq()
      |> map_fields_with_type(field_type)

  defp index_fields_for_render("response" = field_type, questionnaires) do
    order_alphabetically = &(String.downcase(&1) < String.downcase(&2))

    SurveyResults.all_questionnaires_fields(questionnaires)
    |> Enum.sort(&order_alphabetically.(&1, &2))
    |> map_fields_with_type(field_type)
  end

  defp index_fields_for_render("variant" = _field_type, [] = _survey_comparisons), do: []

  defp index_fields_for_render("variant" = field_type, _survey_comparisons),
    do: [index_field_for_render(field_type, "variant")]

  defp index_fields_for_render("partial_relevant" = field_type, true),
    do: map_fields_with_type(["answered_questions"], field_type)

  defp index_fields_for_render("partial_relevant" = _field_type, _), do: []

  defp map_fields_with_type(field_keys, field_type),
    do: Enum.map(field_keys, fn field_key -> index_field_for_render(field_type, field_key) end)

  defp index_field_for_render(field_type, field_key), do: %{type: field_type, key: field_key}

  defp effective_stats(respondent) do
    effective_stats =
      case respondent.stats do
        %{attempts: %{"ivr" => _ivr_attempts}} = stats ->
          effective_attempts = Map.put(stats.attempts, "ivr", Ask.Stats.attempts(stats, :ivr))
          %{stats | attempts: effective_attempts}

        stats ->
          stats
      end

    %{respondent | stats: effective_stats}
  end

  defp sort_respondents(query, sort_by, sort_asc) do
    case {sort_by, sort_asc} do
      {"date", "true"} ->
        query |> order_by([r], asc: r.updated_at)

      {"date", "false"} ->
        query |> order_by([r], desc: r.updated_at)

      {"disposition", "true"} ->
        query |> order_by([r], asc: r.disposition)

      {"disposition", "false"} ->
        query |> order_by([r], desc: r.disposition)

      _ ->
        query
    end
  end

  def stats(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    survey =
      conn
      |> load_project(project_id)
      |> load_survey(survey_id)

    stats(conn, survey, survey.quota_vars)
  rescue
    e ->
      Logger.error(
        e,
        __STACKTRACE__,
        "Error occurred while processing respondent stats (survey_id: #{survey_id})"
      )

      Sentry.capture_exception(e,
        stacktrace: System.stacktrace(),
        extra: %{survey_id: survey_id}
      )

      render(conn, "stats.json", stats: nil)
  end

  defp stats(conn, survey, []) do
    questionnaires = (survey |> Repo.preload(:questionnaires)).questionnaires
    respondent_count = Ask.RespondentStats.respondent_count(survey_id: ^survey.id)

    cond do
      length(questionnaires) > 1 && length(survey.mode) > 1 ->
        stats(
          conn,
          survey,
          respondent_count,
          respondents_by_questionnaire_mode_and_disposition(survey),
          respondents_by_questionnaire_mode_and_completed_at(survey),
          reference(questionnaires, survey.mode),
          [],
          "stats.json"
        )

      length(survey.mode) > 1 ->
        stats(
          conn,
          survey,
          respondent_count,
          respondents_by_mode_and_disposition(survey),
          respondents_by_mode_and_completed_at(survey),
          reference(questionnaires, survey.mode),
          [],
          "stats.json"
        )

      true ->
        stats(
          conn,
          survey,
          respondent_count,
          respondents_by_questionnaire_and_disposition(survey),
          respondents_by_questionnaire_and_completed_at(survey),
          reference(questionnaires, survey.mode),
          [],
          "stats.json"
        )
    end
  end

  defp stats(conn, survey, _) do
    buckets = (survey |> Repo.preload(:quota_buckets)).quota_buckets

    empty_bucket_ids =
      buckets |> Enum.filter(fn bucket -> bucket.quota in [0, nil] end) |> Enum.map(& &1.id)

    buckets = buckets |> Enum.reject(fn bucket -> bucket.quota in [0, nil] end)
    respondent_count = Ask.RespondentStats.respondent_count(survey_id: ^survey.id)

    stats(
      conn,
      survey,
      respondent_count,
      respondents_by_bucket_and_disposition(survey, empty_bucket_ids),
      respondents_by_quota_bucket_and_completed_at(survey, empty_bucket_ids),
      buckets,
      buckets,
      "quotas_stats.json"
    )
  end

  defp stats(
         conn,
         survey,
         total_respondents,
         respondents_by_disposition,
         respondents_by_completed_at,
         references,
         buckets,
         layout
       ) do
    target = target(survey, buckets, total_respondents)

    total_respondents_by_disposition = Ask.RespondentStats.respondents_by_disposition(survey)

    # Completion percentage
    attempted_respondents =
      total_respondents_by_disposition
      |> Enum.filter(fn {d, _} -> d not in [:queued, :registered] end)
      |> Enum.map(fn {_, c} -> c end)
      |> Enum.sum()

    dispositions_for_completion = Respondent.completed_dispositions(survey.count_partial_results)

    completed_or_partial =
      total_respondents_by_disposition
      |> Enum.filter(fn {d, _} -> d in dispositions_for_completion end)
      |> Enum.map(fn {_, c} -> c end)
      |> Enum.sum()

    grouped_respondents =
      respondents_by_completed_at
      |> Enum.reduce(%{}, fn {group_id, date, count}, acc ->
        {_, next_acc} =
          acc
          |> Map.get_and_update(group_id, fn counts_by_date ->
            {counts_by_date, (counts_by_date || []) ++ [{date, count}]}
          end)

        next_acc
      end)

    stats = %{
      id: survey.id,
      reference: references,
      respondents_by_disposition:
        respondent_counts(respondents_by_disposition, total_respondents),
      cumulative_percentages:
        cumulative_percentages(references, grouped_respondents, survey, target, buckets),
      percentages: percentages(survey),
      completion_percentage: completed_or_partial / target * 100,
      total_respondents: total_respondents,
      target: target,
      attempted_respondents: attempted_respondents
    }

    render(conn, layout, stats: stats)
  end

  defp reference([questionnaire], [modes]) do
    [
      %{
        id: questionnaire.id,
        name: questionnaire.name,
        modes: modes
      }
    ]
  end

  defp reference([_], mode) do
    mode
    |> Enum.map(fn modes ->
      %{
        id: modes |> Enum.join(""),
        modes: modes
      }
    end)
  end

  defp reference(questionnaires, [_]) do
    questionnaires
    |> Enum.map(fn q ->
      %{id: q.id, name: q.name}
    end)
  end

  defp reference(questionnaires, mode) do
    questionnaires
    |> Enum.reduce([], fn questionnaire, reference ->
      mode
      |> Enum.reduce(reference, fn modes, reference ->
        reference ++
          [
            %{
              id: "#{questionnaire.id}#{modes |> Enum.join("")}",
              name: questionnaire.name,
              modes: modes
            }
          ]
      end)
    end)
  end

  defp target(survey, buckets, total_respondents) do
    total_quota =
      buckets
      |> Enum.reduce(0, fn bucket, total ->
        total + (bucket.quota || 0)
      end)

    cond do
      total_quota > 0 -> total_quota
      !is_nil(survey.cutoff) -> survey.cutoff
      true -> total_respondents
    end
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
          |> Map.merge(counts[disposition][:by_reference], fn _, count, current_count ->
            count + current_count
          end)

        disposition_total_count = counts[disposition][:count] + count

        counts
        |> Map.put(disposition, %{by_reference: by_reference, count: disposition_total_count})
      end)

    dispositions = [
      "registered",
      "queued",
      "failed",
      "contacted",
      "unresponsive",
      "started",
      "ineligible",
      "rejected",
      "breakoff",
      "refused",
      "interim partial",
      "partial",
      "completed"
    ]

    respondent_counts =
      dispositions
      |> Enum.reduce(respondent_counts, fn disposition, respondent_counts ->
        respondent_counts
        |> Map.put_new(disposition, %{
          by_reference: %{},
          count: 0
        })
      end)

    respondent_counts = add_disposition_percent(respondent_counts, total_respondents)

    groups = %{
      uncontacted: ["registered", "queued", "failed"],
      contacted: ["contacted", "unresponsive"],
      responsive: [
        "started",
        "ineligible",
        "rejected",
        "breakoff",
        "refused",
        "interim partial",
        "partial",
        "completed"
      ]
    }

    groups
    |> Enum.map(fn {name, dispositions} ->
      {count, percent, detail} =
        dispositions
        |> Enum.reduce({0, 0, %{}}, fn disposition, {count_sum, percent_sum, detail} ->
          {respondent_counts[disposition][:count] + count_sum,
           respondent_counts[disposition][:percent] + percent_sum,
           Map.put(detail, disposition, respondent_counts[disposition])}
        end)

      {name, %{count: count, percent: percent, detail: detail}}
    end)
    |> Enum.into(%{})
  end

  defp percent_provider(_group_id, [], target, []) do
    fn count ->
      count / target * 100
    end
  end

  defp percent_provider(group_id, [], _target, buckets) do
    bucket = buckets |> Enum.find(fn bucket -> bucket.id == group_id end)

    fn count ->
      count / bucket.quota * 100
    end
  end

  defp percent_provider(group_id, comparisons, target, []) do
    comparison =
      comparisons
      |> Enum.find(fn comparison ->
        group_id == "#{comparison["questionnaire_id"]}#{comparison["mode"] |> Enum.join("")}" ||
          group_id == comparison["questionnaire_id"] ||
          group_id == comparison["mode"] |> Enum.join("")
      end)

    fn count ->
      count / (comparison["ratio"] * target / 100) * 100
    end
  end

  defp cumulative_percentages(_, _, %{started_at: nil}, _, _), do: %{}

  defp cumulative_percentages(
         references,
         grouped_respondents,
         %{started_at: started_at, comparisons: comparisons, state: state},
         target,
         buckets
       ) do
    grouped_respondents
    |> Enum.into(Enum.map(references, fn reference -> {reference.id, []} end) |> Enum.into(%{}))
    |> Enum.map(fn {group_id, percents_by_date} ->
      # To make sure the series starts at the same time that the survey
      percents_by_date = [{started_at |> DateTime.to_date(), 0}] ++ percents_by_date

      percents_by_date =
        if state == :running do
          percents_by_date ++ [{DateTime.utc_now() |> DateTime.to_date(), 0}]
        else
          percents_by_date
        end

      {group_id,
       cumulative_percents_for_group(
         percents_by_date,
         percent_provider(group_id, comparisons, target, buckets)
       )}
    end)
    |> Enum.into(%{})
  end

  defp cumulative_percents_for_group(
         percents_by_date,
         percent_provider,
         cumulative_percent \\ 0,
         result \\ []
       )

  defp cumulative_percents_for_group(_percents_by_date, _percent_provider, 100.0, result) do
    result
  end

  defp cumulative_percents_for_group(
         [{date, count}],
         percent_provider,
         cumulative_percent,
         result
       ) do
    result ++ [{date, cumulative_percent |> add_percent(count, percent_provider)}]
  end

  defp cumulative_percents_for_group(
         [{first_date, first_count}, {second_date, second_count} | rest_percents_by_date],
         percent_provider,
         cumulative_percent,
         result
       ) do
    case Date.diff(second_date, first_date) do
      0 ->
        # We already had results for that date and we duplicated the dot
        cumulative_percents_for_group(
          [{first_date, max(first_count, second_count)} | rest_percents_by_date],
          percent_provider,
          cumulative_percent,
          result
        )

      1 ->
        cumulative_percent = cumulative_percent |> add_percent(first_count, percent_provider)

        cumulative_percents_for_group(
          [{second_date, second_count} | rest_percents_by_date],
          percent_provider,
          cumulative_percent,
          result ++ [{first_date, cumulative_percent}]
        )

      _ ->
        cumulative_percent = cumulative_percent |> add_percent(first_count, percent_provider)

        if second_count > 0 do
          cumulative_percents_for_group(
            [
              {second_date |> Timex.shift(days: -1), 0},
              {second_date, second_count} | rest_percents_by_date
            ],
            percent_provider,
            cumulative_percent,
            result ++ [{first_date, cumulative_percent}]
          )
        else
          # We injected today's date with no aditional results
          # there's no need for an additional point to mark the horizontal line
          cumulative_percents_for_group(
            [
              {second_date, second_count} | rest_percents_by_date
            ],
            percent_provider,
            cumulative_percent,
            result ++ [{first_date, cumulative_percent}]
          )
        end
    end
  end

  defp add_percent(cumulative_percent, count, percent_provider) do
    (cumulative_percent + percent_provider.(count))
    |> min(100.0)
  end

  defp percentages(%{started_at: nil}), do: %{}

  defp percentages(survey) do
    %{
      success_rate: cleanup_repetitive_percentages(Survey.success_rate_history(survey))
    }
  end

  # Cleanup repetitive values, by skipping any repetitive value except for the
  # first and last, because they don't contribute anything to the graph
  # (straight line).
  #
  # For example take A, B, C, D consecutive dates, each at value 5.0 then we
  # only keep A and D and skip B and C entirely.
  #
  # TODO: consider moving to RespondentView.
  defp cleanup_repetitive_percentages(percentages, result \\ [])
  defp cleanup_repetitive_percentages([], result), do: result
  defp cleanup_repetitive_percentages([a], result), do: result ++ [a]
  defp cleanup_repetitive_percentages([a, b], result), do: result ++ [a, b]

  defp cleanup_repetitive_percentages(
         [{_, value_a} = a, {_, value_b} = b, {_, value_c} = c | rest],
         result
       ) do
    if value_a == value_b && value_a == value_c do
      cleanup_repetitive_percentages([a, c | rest], result)
    else
      cleanup_repetitive_percentages([b, c | rest], result ++ [a])
    end
  end

  defp respondents_by_questionnaire_and_disposition(survey) do
    Ask.RespondentStats.respondent_count(
      survey_id: ^survey.id,
      by: [:state, :disposition, :questionnaire_id]
    )
  end

  defp respondents_by_questionnaire_mode_and_disposition(survey) do
    Ask.RespondentStats.respondent_count(
      survey_id: ^survey.id,
      by: [:state, :disposition, :questionnaire_id, :mode]
    )
    |> Enum.map(fn {state, disposition, questionnaire_id, mode, count} ->
      reference_id =
        if mode && questionnaire_id do
          "#{questionnaire_id}#{mode |> Poison.decode!() |> Enum.join("")}"
        else
          nil
        end

      {state, disposition, reference_id, count}
    end)
  end

  defp respondents_by_mode_and_disposition(survey) do
    Ask.RespondentStats.respondent_count(survey_id: ^survey.id, by: [:state, :disposition, :mode])
  end

  defp respondents_by_bucket_and_disposition(survey, bucket_ids) do
    Ask.RespondentStats.respondent_count(
      survey_id: ^survey.id,
      quota_bucket_id: not_in_list(^bucket_ids),
      by: [:state, :disposition, :quota_bucket_id]
    )
  end

  defp respondents_by_questionnaire_and_completed_at(survey) do
    Repo.all(
      from r in CompletedRespondents,
        where: r.survey_id == ^survey.id,
        group_by: [r.questionnaire_id, r.date],
        order_by: r.date,
        select: {r.questionnaire_id, r.date, fragment("CAST(? AS UNSIGNED)", sum(r.count))}
    )
  end

  defp respondents_by_questionnaire_mode_and_completed_at(survey) do
    Repo.all(
      from r in CompletedRespondents,
        where: r.survey_id == ^survey.id and r.questionnaire_id != 0 and r.mode != "",
        group_by: [r.questionnaire_id, r.mode, r.date],
        order_by: r.date,
        select:
          {r.questionnaire_id, r.mode, r.date, fragment("CAST(? AS UNSIGNED)", sum(r.count))}
    )
    |> Enum.map(fn {questionnaire_id, mode, completed_at, count} ->
      {"#{questionnaire_id}#{mode |> Poison.decode!() |> Enum.join("")}", completed_at, count}
    end)
  end

  defp respondents_by_mode_and_completed_at(survey) do
    Repo.all(
      from r in CompletedRespondents,
        where: r.survey_id == ^survey.id,
        group_by: [r.mode, r.date],
        order_by: r.date,
        select: {r.mode, r.date, fragment("CAST(? AS UNSIGNED)", sum(r.count))}
    )
    |> Enum.map(fn {mode, completed_at, count} ->
      {mode |> Poison.decode!() |> Enum.join(""), completed_at, count}
    end)
  end

  defp respondents_by_quota_bucket_and_completed_at(survey, bucket_ids) do
    Repo.all(
      from r in CompletedRespondents,
        where: r.survey_id == ^survey.id and r.quota_bucket_id not in ^bucket_ids,
        group_by: [r.quota_bucket_id, r.date],
        order_by: r.date,
        select: {r.quota_bucket_id, r.date, fragment("CAST(? AS UNSIGNED)", sum(r.count))}
    )
  end

  defp add_disposition_percent(
         respondents_count_by_disposition_and_questionnaire,
         total_respondents
       ) do
    respondents_count_by_disposition_and_questionnaire
    |> Enum.map(fn {disposition, counts} ->
      percent_of_disposition =
        case total_respondents do
          0 ->
            0

          _ ->
            respondents_count_by_disposition_and_questionnaire[disposition][:count] /
              (total_respondents / 100)
        end

      counts_with_percent = counts |> Map.put(:percent, percent_of_disposition)
      {disposition, counts_with_percent}
    end)
    |> Enum.into(%{})
  end

  def results(conn, %{"project_id" => project_id, "survey_id" => survey_id} = params) do
    project = load_project(conn, project_id)
    survey = load_survey(project, survey_id)

    # The new filters, shared by the index and the downloaded CSV file
    filter = RespondentsFilter.parse(Map.get(params, "q", ""))
    # The old filters are being received by its own specific url params
    # If the same filter is received twice, the old filter is priorized over new one because
    # ?param1=value is more specific than ?q=param1:value
    filter = add_params_to_filter(filter, params)

    # filter_where = RespondentsFilter.filter_where(filter, optimized: true)
    respondents = SurveyResults.survey_respondents_where(survey, filter)

    partial_relevant_enabled = Survey.partial_relevant_enabled?(survey, true)

    respondents_count = Ask.RespondentStats.respondent_count(survey_id: ^survey.id)

    {:ok, conn} =
      Repo.transaction(fn ->
        render(conn, "index.json",
          respondents: respondents,
          respondents_count: respondents_count,
          partial_relevant_enabled: partial_relevant_enabled
        )
      end)

    conn
  end

  def files_status(conn, %{"project_id" => project_id, "survey_id" => survey_id} = params) do
    project = load_project(conn, project_id)
    survey = load_survey(project, survey_id)

    filter = RespondentsFilter.parse(Map.get(params, "q", ""))
    filter = add_params_to_filter(filter, params)

    # FIXME: filter according to permissions
    status = SurveyResults.files_status(survey, [
      {:respondents_results, %RespondentsFilter{}},
      {:respondents_results, filter},
      :interactions,
      :incentives,
      :disposition_history
    ])

    render(conn, "status.json", status: status)
  end

  defp serve_file(conn, survey, file_type) do
    file_path = SurveyResults.file_path(survey, file_type)

    conn
      |> send_download_if_exists(file_path, File.exists?(file_path))
  end

  defp send_download_if_exists(conn, file_path, true), do:
    conn
      |> send_download({:file, file_path})

  defp send_download_if_exists(conn, _file_path, false), do:
    conn
      |> send_resp(404, "File not found")

  def results_csv(conn, %{"project_id" => project_id, "survey_id" => survey_id} = params) do
    project = load_project(conn, project_id)
    survey = load_survey(project, survey_id)

    filter = RespondentsFilter.parse(Map.get(params, "q", ""))
    filter = add_params_to_filter(filter, params)

    ActivityLog.download(project, conn, survey, "survey_results") |> Repo.insert()

    serve_file(conn, survey, {:respondents_results, filter})
  end

  def generate_results(conn, %{"project_id" => project_id, "survey_id" => survey_id} = params) do
    project = load_project(conn, project_id)
    survey = load_survey(project, survey_id)

    # The new filters, shared by the index and the downloaded CSV file
    filter = RespondentsFilter.parse(Map.get(params, "q", ""))
    # The old filters are being received by its own specific url params
    # If the same filter is received twice, the old filter is priorized over new one because
    # ?param1=value is more specific than ?q=param1:value
    filter = add_params_to_filter(filter, params)

    SurveyResults.generate_respondents_results_file(survey_id, filter)

    ActivityLog.generate_file(project, conn, survey, "survey_results") |> Repo.insert()

    conn |> render("ok.json")
  end

  defp add_params_to_filter(filter, params) do
    filter =
      if params["disposition"],
        do: RespondentsFilter.put_disposition(filter, params["disposition"]),
        else: filter

    filter =
      if params["since"],
        do: RespondentsFilter.put_since(filter, params["since"]),
        else: filter

    filter =
      if params["final"],
        do: RespondentsFilter.put_state(filter, "completed"),
        else: filter

    filter
  end

  def generate_disposition_history(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    project = load_project(conn, project_id)
    survey = load_survey(project, survey_id)

    SurveyResults.generate_disposition_history_file(survey.id)

    ActivityLog.generate_file(project, conn, survey, "disposition_history") |> Repo.insert()

    conn |> render("ok.json")
  end

  def disposition_history(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    project = load_project(conn, project_id)
    survey = load_survey(project, survey_id)

    ActivityLog.download(project, conn, survey, "disposition_history") |> Repo.insert()

    serve_file(conn, survey, :disposition_history)
  end

  def incentives(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    project =
      conn
      |> load_project_for_owner(project_id)

    survey =
      project
      |> assoc(:surveys)
      |> where([s], s.incentives_enabled)
      |> Repo.get!(survey_id)

    ActivityLog.download(project, conn, survey, "incentives") |> Repo.insert()

    serve_file(conn, survey, :incentives)
  end

  def generate_incentives(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    project =
      conn
      |> load_project_for_owner(project_id)

    survey =
      project
      |> assoc(:surveys)
      |> where([s], s.incentives_enabled)
      |> Repo.get!(survey_id)

    ActivityLog.generate_file(project, conn, survey, "incentives") |> Repo.insert()

    SurveyResults.generate_incentives_file(survey_id)
    conn |> render("ok.json")
  end

  def interactions(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    project = load_project_for_owner(conn, project_id)
    survey = load_survey(project, survey_id)

    ActivityLog.download(project, conn, survey, "interactions") |> Repo.insert()

    serve_file(conn, survey, :interactions)
  end

  def generate_interactions(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    project = load_project_for_owner(conn, project_id)
    survey = load_survey(project, survey_id)

    ActivityLog.generate_file(project, conn, survey, "interactions") |> Repo.insert()

    SurveyResults.generate_interactions_file(survey_id)
    conn |> render("ok.json")
  end

  defp mask_phone_numbers(respondent) do
    %{respondent | phone_number: Respondent.mask_phone_number(respondent.phone_number)}
  end

  defp load_survey(project, survey_id) do
    project
    |> assoc(:surveys)
    |> Repo.get!(survey_id)
  end
end
