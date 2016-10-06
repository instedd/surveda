defmodule Ask.Runtime.Broker do
  use GenServer
  use Timex
  import Ecto.Query
  import Ecto
  alias Ask.{Repo, Survey, Respondent}
  alias Ask.Runtime.Session

  @batch_size 10
  @poll_interval :timer.minutes(1)
  @server_ref {:global, __MODULE__}

  def server_ref, do: @server_ref

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @server_ref)
  end

  def sync_step(respondent, reply) do
    GenServer.call(@server_ref, {:sync_step, respondent, reply})
  end

  def init(_args) do
    :timer.send_interval(@poll_interval, :poll)
    {:ok, nil}
  end

  def handle_info(:poll, state) do
    surveys = Repo.all(from s in Survey, where: s.state == "running")
    surveys |> Enum.each(&poll_survey(&1))
    {:noreply, state}
  end

  def handle_call({:sync_step, respondent, reply}, _from, state) do
    {:reply, do_sync_step(respondent, reply), state}
  end

  defp poll_survey(survey) do
    by_state = Repo.all(
      from r in assoc(survey, :respondents),
      group_by: :state,
      select: {r.state, count("*")}) |> Enum.into(%{})

    active = by_state["active"] || 0
    pending = by_state["pending"] || 0
    completed = by_state["completed"] || 0

    cond do
      active == 0 && (pending == 0 || survey.cutoff <= completed)->
        Repo.update Survey.changeset(survey, %{state: "completed"})
      survey.cutoff && survey.cutoff > 0 && survey.cutoff - completed < @batch_size && active < @batch_size && pending > 0 ->
        start_some(survey, survey.cutoff - completed - active)
      active < @batch_size && pending > 0 ->
        start_some(survey, @batch_size - active)

      true -> :ok
    end
  end

  defp start_some(survey, count) do
    respondents = Repo.all(
      from r in assoc(survey, :respondents),
      where: r.state == "pending",
      limit: ^count)

    respondents |> Enum.each(&start(survey, &1))
  end

  defp start(survey, respondent) do
    survey = Repo.preload(survey, [:questionnaire, :channels])
    channel = hd(survey.channels)

    case Session.start(survey.questionnaire, respondent, channel) do
      :end ->
        respondent
        |> Respondent.changeset(%{state: "completed", session: nil})
        |> Repo.update

      session ->
        respondent
        |> Respondent.changeset(%{state: "active", session: Session.dump(session)})
        |> Repo.update
    end
  end

  defp do_sync_step(respondent, reply) do
    session = respondent.session |> Session.load

    case Session.sync_step(session, reply) do
      {:ok, session, step} ->
        respondent
        |> Respondent.changeset(%{session: Session.dump(session)})
        |> Repo.update

        step

      :end ->
        respondent
        |> Respondent.changeset(%{state: "completed", session: nil, completed_at: Timex.now})
        |> Repo.update

        :end
    end
  end
end
