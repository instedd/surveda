defmodule Ask.Runtime.SurveyCanceller do
  use Ecto.Schema
  use GenServer
  import Ecto.Query

  alias Ask.{
    ActivityLog,
    Logger,
    Repo,
    Respondent,
    Survey
  }

  alias Ask.Runtime.Session

  alias Ecto.Multi

  def start_link(survey_id) do
    GenServer.start_link(__MODULE__, survey_id)
  end

  @impl true
  def init(survey_id) do
    # FIXME: We only care about the :cancel being async, so we use the smallest timeout possible - but this smells bad
    :timer.send_after(1, :cancel)
    Logger.info("Starting canceller for survey #{survey_id}")
    {:ok, survey_id}
  end

  defp respondents_to_cancel(survey_id) do
    Repo.all(
      from(
        r in Respondent,
        select: r.id,
        where: r.state == :active and r.survey_id == ^survey_id,
        limit: 100
      )
    )
  end

  defp terminate_survey(survey_id) do
    survey = Repo.get(Survey, survey_id)

    changeset =
      Survey.changeset(survey, %{ state: "terminated" })

    Multi.new()
    |> Multi.update(:survey, changeset)
    |> Multi.insert(:log, ActivityLog.completed_cancel(survey))
    |> Repo.transaction()
  end

  defp try_cancel_respondent(respondent) do
    try do
      if respondent.session != nil do
        respondent.session
        |> Session.load()
        |> Session.cancel()
      end

      respondent
      |> Respondent.changeset(%{state: "cancelled", session: nil, timeout_at: nil})
      |> Repo.update!()
    rescue
      error ->
        Logger.error(error, __STACKTRACE__, "Error cancelling respondent #{respondent.id}'s session")
        Sentry.capture_exception(error, extra: %{respondent_id: respondent.id})
    end
  end

  defp cancel_respondents(respondent_ids, survey_id) do
    Logger.debug("Cancelling #{Enum.count(respondent_ids)} respondents for survey #{survey_id}")

    respondent_ids
    |> Enum.each(fn respondent_id -> Respondent.with_lock(respondent_id, &try_cancel_respondent/1) end)
  end

  @impl true
  def handle_info(:cancel, survey_id) do
    Logger.info("Canceller handling :cancel (id: #{survey_id})")

    case respondents_to_cancel(survey_id) do
      [] ->
        terminate_survey(survey_id)
        Logger.info("Finished cancelling survey #{survey_id}")
        {:stop, :normal, nil}

      respondent_ids ->
        cancel_respondents(respondent_ids, survey_id)
        :timer.send_after(1000, :cancel)
        {:noreply, survey_id}
    end
  end

  @impl true
  def handle_info(message, survey_id) do
    Logger.info("Canceller handling #{message} (id: #{survey_id})")
    {:noreply, survey_id}
  end

  def surveys_cancelling() do
    from(
      s in Survey,
      where: s.state == :cancelling,
      select: s.id
    )
    |> Repo.all()
  end
end
