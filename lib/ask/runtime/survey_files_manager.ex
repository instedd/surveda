## This GenServer uses :hibernate since its mailbox might be most of the time empty
##
## Hibernating a GenServer causes garbage collection and leaves a continuous 
## heap that minimizes the memory used by the process.
##
## When a process is hibernated it will continue the loop once a message is in its
## message queue. If when returning a handle_* call there is already a message
## in the message queue, the process will continue the loop immediately. 
defmodule Ask.Runtime.SurveyFilesManager do
  use GenServer
  alias Ask.{Logger, Repo, Survey, SurveyLogEntry}
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
    Logger.info("SurveyFilesManager started")
    {:ok, state}
  end

  defp do_generate_interactions_file(survey) do
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

    filename = csv_filename(survey, file_prefix(:interactions))
    File.mkdir_p!(@target_dir)
    file = File.open!("#{@target_dir}/#{filename}", [:write, :utf8])
    initial_datetime = Timex.now()

    rows
    |> CSV.encode()
    |> Enum.each(&IO.write(file, &1))

    seconds_to_process_file = Timex.diff(Timex.now(), initial_datetime, :seconds)

    Logger.info(
      "Generation of interaction files survey (id #{survey.id}) took #{seconds_to_process_file} seconds"
    )
  end

  defp file_prefix(:interactions), do: "respondents_interactions"
  defp file_prefix(_), do: ""

  defp should_generate_file(:interactions, survey) do
    # TODO: when do we want to skip the re-generation of the file?
    existing_files = File.ls!(@target_dir)

    exists_file =
      existing_files
      |> Enum.any?(fn file ->
        file |> String.starts_with?(survey_filename_prefix(survey, file_prefix(:interactions)))
      end)

    !exists_file
  end

  @impl true
  def handle_cast({:interactions, survey_id}, state) do
    survey = Repo.get!(Survey, survey_id)

    if should_generate_file(:interactions, survey) do
      do_generate_interactions_file(survey)
    else
      Logger.info("Ignoring generation of :interaction file")
    end
    {:noreply, state, :hibernate}
  end

  @impl true
  def handle_cast(message, state) do
    Logger.warn("Ignoring message #{message}")
    {:noreply, state, :hibernate}
  end

  defp survey_log_entry_channel_names(survey) do
    respondent_groups = Repo.preload(survey, respondent_groups: [:channels]).respondent_groups

    respondent_groups 
    |> Enum.flat_map(fn resp_group -> resp_group.channels end)
    |> Enum.map( fn channel -> {channel.id, channel.name} end) 
    |> MapSet.new # convert to set to remove duplicates
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

  # FIXME: duplicated from respondent_controller
  defp csv_filename(survey, prefix) do
    prefix = survey_filename_prefix(survey, prefix)
    Timex.format!(DateTime.utc_now(), "#{prefix}_%Y-%m-%d-%H-%M-%S.csv", :strftime)
  end

  defp survey_filename_prefix(survey, prefix) do
    name = survey.name || "survey_id_#{survey.id}"
    name = Regex.replace(~r/[^a-zA-Z0-9_]/, name, "_")
    "#{name}_#{survey.state}-#{prefix}"
  end

  # FIXME: duplicated from respondent_controller
  defp csv_datetime(nil, _, _), do: ""

  defp csv_datetime(dt, tz_offset_in_seconds, tz_offset) when is_binary(dt) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(dt)
    csv_datetime(datetime, tz_offset_in_seconds, tz_offset)
  end

  defp csv_datetime(dt, tz_offset_in_seconds, tz_offset) do
    Ask.TimeUtil.format(dt, tz_offset_in_seconds, tz_offset)
  end

  ## Public API
  def generate_interactions_file(survey_id) do
    Logger.info("Enqueueing generation of survey (id: #{survey_id}) interaction file")
    GenServer.cast(server_ref(), {:interactions, survey_id})
  end
end
