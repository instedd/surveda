## This GenServer uses :hibernate since its mailbox might be most of the time empty
##
## Hibernating a GenServer causes garbage collection and leaves a continuous 
## heap that minimizes the memory used by the process.
##
## When a process is hibernated it will continue the loop once a message is in its
## message queue. If when returning a handle_* call there is already a message
## in the message queue, the process will continue the loop immediately. 
defmodule Ask.SurveyResults do
  use GenServer
  require Ask.RespondentStats

  alias Ask.{
    Logger,
    Questionnaire,
    Repo,
    Respondent,
    RespondentDispositionHistory,
    RespondentsFilter,
    Stats,
    Survey,
    SurveyLogEntry
  }

  import Ecto.Query

  @db_chunk_limit 10_000
  @target_dir "generated_files"

  @server_ref {:global, __MODULE__}
  def server_ref, do: @server_ref

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: @server_ref)
  end

  @impl true
  def init(state) do
    Logger.info("SurveyResults started")
    {:ok, state}
  end

  @impl true
  def handle_cast({file_type, survey_id, args}, state) do
    survey = Repo.get!(Survey, survey_id)

    generate_file(file_type, survey, args)

    {:noreply, state, :hibernate}
  end

  @impl true
  def handle_cast(message, state) do
    Logger.warn("Ignoring message #{message}")
    {:noreply, state, :hibernate}
  end

  defp generate_file(:interactions, survey, _) do
    channels = survey_log_entry_channel_names(survey)

    Logger.info("Starting to build interaction file (survey_id: #{survey.id})")

    log_entries =
      Stream.resource(
        fn -> {"", 0} end,
        fn {last_hash, last_id} ->
          results =
            from(e in SurveyLogEntry,
              where:
                e.survey_id == ^survey.id and
                  ((e.respondent_hashed_number == ^last_hash and e.id > ^last_id) or
                     e.respondent_hashed_number > ^last_hash),
              order_by: [e.respondent_hashed_number, e.id],
              limit: @db_chunk_limit
            )
            |> Repo.all()

          case List.last(results) do
            nil -> {:halt, {last_hash, last_id}}
            last_entry -> {results, {last_entry.respondent_hashed_number, last_entry.id}}
          end
        end,
        fn _ -> [] end
      )

    tz_offset_in_seconds = Survey.timezone_offset_in_seconds(survey)
    tz_offset = Survey.timezone_offset(survey)

    csv_rows =
      log_entries
      |> Stream.map(fn e ->
        [
          Integer.to_string(e.id),
          e.respondent_hashed_number,
          interactions_mode_label(e.mode),
          Map.get(channels, e.channel_id, ""),
          disposition_label(e.disposition),
          action_type_label(e.action_type),
          e.action_data,
          csv_datetime(e.timestamp, tz_offset_in_seconds, tz_offset)
        ]
      end)

    header = [
      "ID",
      "Respondent ID",
      "Mode",
      "Channel",
      "Disposition",
      "Action Type",
      "Action Data",
      "Timestamp"
    ]

    rows = Stream.concat([[header], csv_rows])

    write_to_file(:interactions, survey, rows)
  end

  defp generate_file(:incentives, survey, _) do
    questionnaires = survey_respondent_questionnaires(survey)

    tz_offset_in_seconds = Survey.timezone_offset_in_seconds(survey)
    tz_offset = Survey.timezone_offset(survey)

    Repo.transaction(fn ->
      csv_rows =
        from(r in Respondent,
          where:
            r.survey_id == ^survey.id and r.disposition == :completed and
              not is_nil(r.questionnaire_id),
          order_by: r.id
        )
        |> Repo.stream()
        |> Stream.map(fn r ->
          questionnaire = Enum.find(questionnaires, fn q -> q.id == r.questionnaire_id end)

          [
            r.phone_number,
            experiment_name(questionnaire, r.mode),
            csv_datetime(r.completed_at, tz_offset_in_seconds, tz_offset)
          ]
        end)

      header = ["Telephone number", "Questionnaire-Mode", "Completion date"]
      rows = Stream.concat([[header], csv_rows])

      write_to_file(:incentives, survey, rows)
    end)
  end

  defp generate_file(:unused_sample, survey, _) do
    # FIXME: only generate if survey is finished
    Repo.transaction(fn ->
      csv_rows =
        from(r in Respondent,
          where:
            r.survey_id == ^survey.id and r.disposition == :registered,
          order_by: r.phone_number
        )
        |> Repo.stream()
        |> Stream.map(fn r ->
          [r.phone_number,r.disposition,r.state]
        end)
      header = ["Telephone number", "Disposition", "State"]
      rows = Stream.concat([[header], csv_rows])
      write_to_file(:unused_sample, survey, rows)
    end)
  end

  defp generate_file(:disposition_history, survey, _) do
    history =
      Stream.resource(
        fn -> 0 end,
        fn last_id ->
          results =
            from(h in RespondentDispositionHistory,
              where: h.survey_id == ^survey.id and h.id > ^last_id,
              order_by: h.id,
              limit: @db_chunk_limit
            )
            |> Repo.all()

          case List.last(results) do
            nil -> {:halt, last_id}
            last_entry -> {results, last_entry.id}
          end
        end,
        fn _ -> [] end
      )

    tz_offset_in_seconds = Survey.timezone_offset_in_seconds(survey)
    tz_offset = Survey.timezone_offset(survey)

    csv_rows =
      history
      |> Stream.map(fn history ->
        [
          history.respondent_hashed_number,
          history.disposition,
          mode_label([history.mode]),
          csv_datetime(history.inserted_at, tz_offset_in_seconds, tz_offset)
        ]
      end)

    header = ["Respondent ID", "Disposition", "Mode", "Timestamp"]
    rows = Stream.concat([[header], csv_rows])
    write_to_file(:disposition_history, survey, rows)
  end

  defp generate_file(:respondents_results, survey, filter) do
    tz_offset = Survey.timezone_offset(survey)

    questionnaires = (survey |> Repo.preload(:questionnaires)).questionnaires
    all_fields = all_questionnaires_fields(questionnaires, true)
    has_comparisons = length(survey.comparisons) > 0

    respondents = survey_respondents_where(survey, filter)

    stats =
      survey.mode
      |> Enum.flat_map(fn modes ->
        modes
        |> Enum.flat_map(fn mode ->
          case mode do
            "sms" -> [:total_sent_sms, :total_received_sms, :sms_attempts]
            "mobileweb" -> [:total_sent_sms, :total_received_sms, :mobileweb_attempts]
            "ivr" -> [:total_call_time, :ivr_attempts]
            _ -> []
          end
        end)
      end)
      |> Enum.uniq()

    tz_offset_in_seconds = Survey.timezone_offset_in_seconds(survey)
    partial_relevant_enabled = Survey.partial_relevant_enabled?(survey, true)

    # Now traverse each respondent and create a row for it
    csv_rows =
      respondents
      |> Stream.map(fn respondent ->
        row = [respondent.hashed_number]
        responses = respondent.responses

        row = row ++ [Respondent.show_disposition(respondent.disposition)]

        date =
          case responses do
            [] ->
              nil

            _ ->
              responses
              |> Enum.map(fn r -> r.updated_at end)
              |> Enum.max()
          end

        row =
          if date do
            row ++ [Ask.TimeUtil.format2(date, tz_offset_in_seconds, tz_offset)]
          else
            row ++ ["-"]
          end

        modes =
          (respondent.effective_modes || [])
          |> Enum.map(fn mode -> mode_label([mode]) end)
          |> Enum.join(", ")

        row = row ++ [modes]

        row = row ++ [respondent.user_stopped]

        row =
          row ++
            Enum.map(stats, fn stat ->
              respondent |> respondent_stat(stat)
            end)

        row = row ++ [Respondent.show_section_order(respondent, questionnaires)]

        respondent_group = respondent.respondent_group.name

        row = row ++ [respondent_group]

        questionnaire_id = respondent.questionnaire_id
        questionnaire = questionnaires |> Enum.find(fn q -> q.id == questionnaire_id end)
        mode = respondent.mode

        row =
          if has_comparisons do
            variant =
              if questionnaire && mode do
                experiment_name(questionnaire, mode)
              else
                "-"
              end

            row ++ [variant]
          else
            row
          end

        row =
          if partial_relevant_enabled do
            respondent_with_questionnaire = %{respondent | questionnaire: questionnaire}

            row ++
              [Respondent.partial_relevant_answered_count(respondent_with_questionnaire, false)]
          else
            row
          end

        # We traverse all fields and see if there's a response for this respondent
        row =
          all_fields
          |> Enum.reduce(row, fn field_name, acc ->
            response =
              responses
              |> Enum.filter(fn response ->
                response.field_name |> sanitize_variable_name() == field_name
              end)

            case response do
              [resp] ->
                value = resp.value

                # For the 'language' variable we convert the code to the native name
                value =
                  if resp.field_name == "language" do
                    LanguageNames.for(value) || value
                  else
                    value
                  end

                acc ++ [value]

              _ ->
                acc ++ [""]
            end
          end)

        row
      end)

    append_if = fn list, elems, condition -> if condition, do: list ++ elems, else: list end

    # Add header to csv_rows
    header = ["respondent_id", "disposition", "date", "modes", "user_stopped"]

    header =
      header ++
        Enum.map(stats, fn stat ->
          case stat do
            :total_sent_sms -> "total_sent_sms"
            :total_received_sms -> "total_received_sms"
            :total_call_time -> "total_call_time"
            :sms_attempts -> "sms_attempts"
            :ivr_attempts -> "ivr_attempts"
            :mobileweb_attempts -> "mobileweb_attempts"
          end
        end)

    header = header ++ ["section_order", "sample_file"]
    header = append_if.(header, ["variant"], has_comparisons)
    header = append_if.(header, ["p_relevants"], partial_relevant_enabled)
    header = header ++ all_fields

    rows = Stream.concat([[header], csv_rows])

    write_to_file({:respondents_results, filter}, survey, rows)
  end

  def file_path(survey, file_type, target_dir \\ @target_dir) do
    suffix = file_suffix(file_type)
    "#{target_dir}/survey_#{survey.id}-#{survey.state}-#{suffix}.csv"
  end

  defp write_to_file(file_type, survey, rows) do
    File.mkdir_p!(@target_dir)
    target_file = file_path(survey, file_type, @target_dir)
    if File.exists?(target_file), do: File.rm!(target_file)

    # Poor man's mktemp. We only want to avoid having the file living at the stable
    # path while it's still being written to avoid partial downloads
    temporal_file_name = for _ <- 1..10, into: "#{target_file}.tmp.", do: <<Enum.random(?a..?z)>>
    temporal_file = File.open!(temporal_file_name, [:write, :utf8])
    initial_datetime = Timex.now()

    rows
    |> CSV.encode()
    |> Enum.each(&IO.write(temporal_file, &1))

    File.rename!(temporal_file_name, target_file)

    seconds_to_process_file = Timex.diff(Timex.now(), initial_datetime, :seconds)

    Logger.info(
      "Generation of #{file_suffix(file_type)} file (survey_id: #{survey.id}) took #{seconds_to_process_file} seconds"
    )
  end

  def files_status(survey, file_types) do
    %{
      survey_id: survey.id,
      survey_state: survey.state,
      files:
        file_types
        |> Enum.uniq
        |> Map.new(fn file_type -> {file_type_symbol(file_type), file_status(survey, file_type)} end)
    }
  end

  defp file_creating?(target_path), do: Path.wildcard(target_path <> ".tmp.*") |> Enum.any?

  defp created_at(_path, false), do: nil
  defp created_at(path, true) do
    case File.stat(path, [time: :posix]) do
      {:ok, %{ mtime: last_mod }} -> last_mod
      _ -> nil
    end
  end

  defp file_type_symbol({:respondents_results, filter}) do
    if RespondentsFilter.empty?(filter) do
      :respondents_results
    else
      :respondents_filtered
    end
  end
  defp file_type_symbol(type), do: type

  defp file_status(survey, file_type) do
    path = file_path(survey, file_type)
    exists = File.exists?(path)
    %{
      file_type: file_type_symbol(file_type),
      creating: file_creating?(path),
      created_at: created_at(path, exists)
    }
  end

  defp filter_hash(filter) do
    filter
      |> :erlang.phash2
      |> to_string
  end

  defp file_suffix(:interactions), do: "respondents_interactions"
  defp file_suffix(:incentives), do: "respondents_incentives"
  defp file_suffix(:unused_sample), do: "unused_sample"
  defp file_suffix(:disposition_history), do: "disposition_history"
  defp file_suffix(:respondents_results), do: "respondents"
  defp file_suffix({:respondents_results, filter}) do
    if RespondentsFilter.empty?(filter) do
      "respondents"
    else
      # Hashing the filter object avoids dealing with the order of the params in the filter
      # (ie, "disposition:queued mode:sms" vs "mode:sms disposition:queued"), and avoids `:`
      # and ` ` characters in the file name
      "respondents_filtered_#{filter_hash(filter)}"
    end
  end

  defp survey_log_entry_channel_names(survey) do
    respondent_groups = Repo.preload(survey, respondent_groups: [:channels]).respondent_groups

    respondent_groups
    |> Enum.flat_map(fn resp_group -> resp_group.channels end)
    |> Enum.map(fn channel -> {channel.id, channel.name} end)
    # convert to set to remove duplicates
    |> MapSet.new()
    |> Enum.into(%{})
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

  defp csv_datetime(nil, _, _), do: ""

  defp csv_datetime(dt, tz_offset_in_seconds, tz_offset) when is_binary(dt) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(dt)
    csv_datetime(datetime, tz_offset_in_seconds, tz_offset)
  end

  defp csv_datetime(dt, tz_offset_in_seconds, tz_offset) do
    Ask.TimeUtil.format(dt, tz_offset_in_seconds, tz_offset)
  end

  defp survey_respondent_questionnaires(survey) do
    from(q in Questionnaire,
      where:
        q.id in subquery(
          from(r in Respondent,
            distinct: true,
            select: r.questionnaire_id,
            where: r.survey_id == ^survey.id
          )
        )
    )
    |> Repo.all()
  end

  defp respondent_stat(respondent, :sms_attempts), do: respondent.stats |> Stats.attempts(:sms)
  defp respondent_stat(respondent, :ivr_attempts), do: respondent.stats |> Stats.attempts(:ivr)

  defp respondent_stat(respondent, :mobileweb_attempts),
    do: respondent.stats |> Stats.attempts(:mobileweb)

  defp respondent_stat(respondent, key), do: apply(Stats, key, [respondent.stats])

  def sanitize_variable_name(variable), do: variable |>  String.trim() |> String.replace(" ", "_")
  
  defp sanitize_variable_names(fields),
    do: Enum.map(fields, &sanitize_variable_name/1)

  defp experiment_name(quiz, mode) do
    "#{questionnaire_name(quiz)} - #{mode_label(mode)}"
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

  defp questionnaire_name(quiz) do
    quiz.name || "Untitled questionnaire"
  end

  ## Public GenServer API
  def generate_interactions_file(survey_id) do
    Logger.info("Enqueueing generation of survey (id: #{survey_id}) interaction file")
    GenServer.cast(server_ref(), {:interactions, survey_id, nil})
  end

  def generate_incentives_file(survey_id) do
    Logger.info("Enqueueing generation of survey (id: #{survey_id}) incentives file")
    GenServer.cast(server_ref(), {:incentives, survey_id, nil})
  end

  def generate_unused_sample_file(survey_id) do
    Logger.info("Enqueueing generation of survey (id: #{survey_id}) unused_sample file")
    GenServer.cast(server_ref(), {:unused_sample, survey_id, nil})
  end

  def generate_disposition_history_file(survey_id) do
    Logger.info("Enqueueing generation of survey (id: #{survey_id}) disposition_history file")
    GenServer.cast(server_ref(), {:disposition_history, survey_id, nil})
  end

  def generate_respondents_results_file(survey_id, filters) do
    Logger.info("Enqueueing generation of survey (id: #{survey_id}) respondents_results file")
    GenServer.cast(server_ref(), {:respondents_results, survey_id, filters})
  end

  ## Public Module
  def survey_respondents_where(survey, filter) do
    filter_where = RespondentsFilter.filter_where(filter, optimized: true)

    respondents =
      Stream.resource(
        fn -> 0 end,
        fn last_seen_id ->
          results =
            from(r1 in Respondent,
              join: r2 in Respondent,
              on: r1.id == r2.id,
              where: r2.survey_id == ^survey.id and r2.id > ^last_seen_id,
              where: ^filter_where,
              order_by: r2.id,
              limit: @db_chunk_limit,
              preload: [:responses, :respondent_group],
              select: r1
            )
            |> Repo.all()

          case List.last(results) do
            %{id: last_id} -> {results, last_id}
            nil -> {:halt, last_seen_id}
          end
        end,
        fn _ -> [] end
      )

    survey_has_comparisons = length(survey.comparisons) > 0
    questionnaires = (survey |> Repo.preload(:questionnaires)).questionnaires

    if survey_has_comparisons do
      respondents
      |> Stream.map(fn respondent ->
        experiment_name =
          if respondent.questionnaire_id && respondent.mode do
            questionnaire =
              questionnaires |> Enum.find(fn q -> q.id == respondent.questionnaire_id end)

            if questionnaire do
              experiment_name(questionnaire, respondent.mode)
            else
              "-"
            end
          else
            "-"
          end

        %{respondent | experiment_name: experiment_name}
      end)
    else
      respondents
    end
  end

  def all_questionnaires_fields(questionnaires, sanitize \\ false) do
    fields =
    questionnaires
    |> Enum.flat_map(&Questionnaire.variables/1)
    |> Enum.uniq()
    |> Enum.reject(fn s -> String.length(s) == 0 end)
    
    if sanitize, do: sanitize_variable_names(fields), else: fields
  end
end
