defmodule Ask.BrokerStub do
  use GenServer

  @server_ref {:global, __MODULE__}
  def server_ref, do: @server_ref

  def sync_step(respondent, reply) do
    GenServer.call(@server_ref, {:sync_step, respondent, reply})
  end

  def handle_cast({:expects, matcher}, _) do
    {:noreply, matcher}
  end

  def handle_call(call, _from, matcher) do
    {:reply, matcher.(call), matcher}
  end
end
