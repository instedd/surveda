defmodule Ask.Runtime.ChannelBrokerSupervisor do
  # Automatically defines child_spec/1
  use DynamicSupervisor

  def start_link(init_arg) do
    # TODO: find out why this is not printed in console
    IO.inspect("-------------start link")
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    IO.inspect("------------------------ChannelBrokerSupervisor")
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
