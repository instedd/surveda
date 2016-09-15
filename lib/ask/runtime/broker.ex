defmodule Ask.Runtime.Broker do
  use GenServer
  import Ecto.Query
  import Ecto
  alias Ask.{ Repo, Survey, Respondent }

  @batch_size 10

  def init(_args) do
    :timer.send_interval(1000, :poll)
    {:ok, nil}
  end

  def handle_info(:poll, state) do
    surveys = Repo.all(from s in Survey, where: s.state == "running")
    surveys |> Enum.each(fn(survey) -> poll_survey(survey) end)
    {:noreply, state}
  end

  defp poll_survey(survey) do
    by_state = Repo.all(
      from r in assoc(survey, :respondents),
      group_by: :state,
      select: {r.state, count("*")}) |> Enum.into(%{})

    active = by_state["active"] || 0
    pending = by_state["pending"] || 0

    cond do
      active == 0 && pending == 0 ->
        Repo.update Survey.changeset(survey, %{state: "completed"})

      active < @batch_size && pending > 0 ->
        enqueue_some(survey, @batch_size - active)

      true -> :ok
    end
  end

  defp enqueue_some(survey, count) do
    respondents = Repo.all(
      from r in assoc(survey, :respondents),
      where: r.state == "pending",
      limit: ^count)

    respondents |> Enum.each(fn(respondent) -> enqueue(survey, respondent) end)
  end

  defp enqueue(_survey, respondent) do
    Repo.update Respondent.changeset(respondent, %{state: "active"})
  end
end
