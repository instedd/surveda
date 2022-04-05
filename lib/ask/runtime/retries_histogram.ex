defmodule Ask.Runtime.RetriesHistogram do
  alias Ask.{RetryStat, Stats, SystemTime, Logger, Respondent, Repo}
  alias Ask.Runtime.Session

  def add_new_respondent(respondent, session, timeout) do
    callback = fn ->
      %Respondent{} = respondent
      %Session{} = session
      ivr_active? = ivr?(session)

      if(respondent.retry_stat_id) do
        # This shouldn't happen but just-in-case to avoid showing more respondents than the survey-actual-respondents-size
        prev_stat_id = respondent.retry_stat_id
        respondent = reallocate_respondent(session, respondent, ivr_active?, timeout).respondent

        Logger.warn(
          "Adding again respondent (id: #{respondent.id}) to the histogram. Actual retry_stat_id: #{
            respondent.retry_stat_id
          }, previous: #{prev_stat_id}"
        )

        respondent
      else
        {:ok, retry_stat} = RetryStat.add(retry_stat_group(respondent, ivr_active?, timeout))
        update_respondent(respondent, retry_stat.id)
      end
    end

    run_safe(%{
      callback: callback,
      rescue_result: respondent,
      error_message: "Error adding new respondent to histogram"
    })
  end

  # only makes sense for verboice
  def respondent_no_longer_active(respondent) do
    # transition from ivr active to normal retryStat
    callback = fn ->
      %Respondent{} = respondent
      %Session{} = session = Session.load(respondent.session)

      session =
        reallocate_respondent(session, respondent, false, Session.current_timeout(session))

      session.respondent
    end

    run_safe(%{
      callback: callback,
      rescue_result: respondent,
      error_message: "Error deactivating ivr respondent in RetriesHistogram"
    })
  end

  def retry(session) do
    callback = fn ->
      %Session{respondent: %Respondent{} = respondent} = session
      reallocate_respondent(session, respondent, ivr?(session), Session.current_timeout(session))
    end

    run_safe(%{
      callback: callback,
      rescue_result: session,
      error_message: "Error handling retry in RetriesHistogram"
    })
  end

  def next_step(respondent, session, next_action),
    do:
      run_safe(%{
        callback: fn -> do_next_step(respondent, session, next_action) end,
        rescue_result: respondent,
        error_message: "Error handling next_step in RetriesHistogram"
      })

  def remove_respondent(respondent) do
    callback = fn ->
      %Respondent{retry_stat_id: retry_stat_id} = respondent
      RetryStat.subtract(retry_stat_id)
      update_respondent(respondent, nil)
    end

    run_safe(%{
      callback: callback,
      rescue_result: respondent,
      error_message: "Error removing the respondent in RetriesHistogram"
    })
  end

  defp run_safe(%{callback: callback, rescue_result: rescue_result, error_message: error_message}) do
    try do
      callback.()
    rescue
      e ->
        Logger.error(e, __STACKTRACE__, error_message)
        rescue_result
    end
  end

  defp update_respondent(%Respondent{} = respondent, retry_stat_id),
    do:
      respondent
      |> Respondent.changeset(%{retry_stat_id: retry_stat_id})
      |> Repo.update!()

  defp ivr?(%Session{current_mode: %Ask.Runtime.IVRMode{}}), do: true
  defp ivr?(%Session{current_mode: _}), do: false

  defp retry_stat_group(
         %Respondent{stats: stats, mode: mode, survey_id: survey_id},
         ivr_active?,
         timeout
       ) do
    retry_time =
      Respondent.next_timeout_lowerbound(timeout, SystemTime.time().now) |> RetryStat.retry_time()

    %{
      attempt: stats |> Stats.attempts(:full),
      mode: mode,
      retry_time: retry_time,
      ivr_active: ivr_active?,
      survey_id: survey_id
    }
  end

  defp reallocate_respondent(
         %Session{} = session,
         %Respondent{retry_stat_id: retry_stat_id} = respondent,
         ivr_active?,
         timeout
       ) do
    {:ok, retry_stat} =
      RetryStat.transition(
        retry_stat_id,
        retry_stat_group(respondent, ivr_active?, timeout)
      )

    %Session{session | respondent: update_respondent(respondent, retry_stat.id)}
  end

  defp do_next_step(
         %Respondent{} = respondent,
         %Session{current_mode: %Ask.Runtime.SMSMode{}} = session,
         {:reply, _reply, _}
       ) do
    # sms -> transition to active RetryStat
    if respondent.retry_stat_id,
      do: reallocate_respondent(session, respondent, false, Session.current_timeout(session))
  end

  defp do_next_step(_respondent, _session, {:reply, _reply, _}) do
    # ivr -> do nothing, respondent is on call
    # mobile-web -> do nothing
  end

  defp do_next_step(%Respondent{} = respondent, _session, {:end, _reply, _}) do
    # remove respondent from histogram
    remove_respondent(respondent)
  end

  defp do_next_step(%Respondent{} = respondent, _session, {:end, _}) do
    # remove respondent from histogram
    remove_respondent(respondent)
  end
end
