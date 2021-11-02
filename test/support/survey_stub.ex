defmodule Ask.Runtime.SurveyStub do
  use GenServer

  @server_ref {:global, __MODULE__}
  def server_ref, do: @server_ref

  def init(args) do
    {:ok, args}
  end

  def sync_step(respondent, reply, mode) do
    GenServer.call(@server_ref, {:sync_step, respondent, reply, mode})
  end

  def handle_cast({:expects, matcher}, _) do
    {:noreply, matcher}
  end

  def handle_call(call, _from, matcher) do
    {:reply, matcher.(call), matcher}
  end
end
