defmodule Ask.Runtime.Broker do
  use GenServer
  import Ecto.Query
  alias Ask.{Repo, Survey}

  def init(_args) do
    :timer.send_interval(1000, :poll)
    {:ok, nil}
  end

  def handle_info(:poll, state) do
    surveys = Repo.all(from s in Survey, where: s.state == "running")
    surveys |> Enum.each(fn(survey) ->
      Repo.update Survey.changeset(survey, %{state: "done"})
    end)
    {:noreply, state}
  end
end
