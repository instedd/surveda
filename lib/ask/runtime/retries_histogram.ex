defmodule Ask.Runtime.RetriesHistogram do
  alias Ask.{RetryStat, Stats, SystemTime, Logger, Respondent, Repo}
  alias Ask.Runtime.Session

  def add_new_respondent(respondent, session, timeout) do
    try do
      %Respondent{} = respondent
      %Session{} = session
      {:ok, retry_stat} = RetryStat.add(retry_stat_group(respondent, ivr?(session), timeout))
      update_respondent(respondent, retry_stat.id)
    rescue
      _ -> Logger.error("Error adding new respondent to histogram")
      respondent
    end
  end

  def respondent_no_longer_active(respondent) do # only makes sense for verboice
    # transition from ivr active to normal retryStat
    try do
      %Respondent{} = respondent
      %Session{} = session = Session.load(respondent.session)
      session = reallocate_respondent(session, respondent, false, Session.current_timeout(session))
      session.respondent
    rescue
      _ -> Logger.error("Error deactivating ivr respondent in RetriesHistogram")
      respondent
    end
  end

  def retry(session) do
    try do
      %Session{respondent: %Respondent{} = respondent} = session
      reallocate_respondent(session, respondent, ivr?(session), Session.current_timeout(session))
    rescue
      _ -> Logger.error("Error handling retry in RetriesHistogram")
      session
    end
  end

  def next_step(respondent, session, next_action) do
    try do
      do_next_step(respondent, session, next_action)
    rescue
      _ -> Logger.error("Error handling next_step in RetriesHistogram")
     session
    end
  end

  def remove_respondent(respondent) do
    try do
      %Respondent{retry_stat_id: retry_stat_id} = respondent
      RetryStat.subtract(retry_stat_id)
      update_respondent(respondent, nil)
    rescue
      e -> Logger.error("Error removing the respondent in RetriesHistogram: " <> e.message)
      respondent
    end
  end

  defp update_respondent(%Respondent{} = respondent, retry_stat_id),
    do:
      respondent
      |> Respondent.changeset(%{retry_stat_id: retry_stat_id})
      |> Repo.update!

  defp ivr?(%Session{current_mode: %Ask.Runtime.IVRMode{}}), do: true
  defp ivr?(%Session{current_mode: _}), do: false

  defp retry_stat_group(%Respondent{stats: stats, mode: mode, survey_id: survey_id}, ivr_active?, timeout) do
    retry_time = Respondent.next_timeout_lowerbound(timeout, SystemTime.time.now) |> RetryStat.retry_time
    %{attempt: stats |> Stats.attempts(:all), mode: mode, retry_time: retry_time, ivr_active: ivr_active?, survey_id: survey_id}
  end

  defp reallocate_respondent(%Session{} = session, %Respondent{retry_stat_id: retry_stat_id} = respondent, ivr_active?, timeout) do
    {:ok, retry_stat} = RetryStat.transition(
      retry_stat_id,
      retry_stat_group(respondent, ivr_active?, timeout)
    )
    %Session{ session | respondent: update_respondent(respondent, retry_stat.id)}
  end

  defp do_next_step(%Respondent{} = respondent, %Session{current_mode: %Ask.Runtime.SMSMode{}} = session, {:reply, _reply}) do
    # sms -> transition to active RetryStat
    if respondent.retry_stat_id, do:
      reallocate_respondent(session, respondent, false, Session.current_timeout(session))
  end

  defp do_next_step(_respondent, _session, {:reply, _reply}) do
    # ivr -> do nothing, respondent is on call
    # mobile-web -> do nothing
  end

  defp do_next_step(%Respondent{} = respondent, _session, {:end, _reply}) do
    # remove respondent from histogram
    remove_respondent(respondent)
  end

  defp do_next_step(%Respondent{} = respondent, _session, :end) do
    # remove respondent from histogram
    remove_respondent(respondent)
  end
end
