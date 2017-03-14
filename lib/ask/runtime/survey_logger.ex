defmodule Ask.Runtime.SurveyLogger do
  use GenServer
  use Timex
  alias Ask.{Repo, SurveyLogEntry}
  require Logger

  @server_ref {:global, __MODULE__}

  def server_ref, do: @server_ref

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @server_ref)
  end

  def log(survey_id, mode, respondent_id, respondent_hash, channel_id, disposition, action_type, action_data, timestamp \\ Timex.now) do
    GenServer.cast(@server_ref, {:log, survey_id, mode, respondent_id, respondent_hash, channel_id, disposition, action_type, action_data, timestamp})
  end

  def init(_args) do
    {:ok, nil}
  end

  def handle_cast({:log, survey_id, mode, respondent_id, respondent_hash, channel_id, disposition, action_type, action_data, timestamp}, state) do
    Logger.debug "Survey log entry: #{survey_id} #{mode} #{respondent_id} #{respondent_hash} #{channel_id} #{disposition} #{action_type} #{action_data} #{timestamp}"

    action_type = case action_type do
      type when is_atom(type) -> Atom.to_string(type)
      type -> type
    end

    %SurveyLogEntry{
      survey_id: survey_id,
      mode: mode,
      respondent_id: respondent_id,
      respondent_hashed_number: respondent_hash,
      channel_id: channel_id,
      disposition: disposition,
      action_type: action_type,
      action_data: action_data,
      timestamp: Ecto.DateTime.cast!(timestamp)
    } |> Repo.insert!

    {:noreply, state}
  end
end
