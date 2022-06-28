defmodule Ask.Runtime.ChannelBrokerSupervisor do
  alias Ask.Runtime.ChannelBroker
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    # TODO: start a channel broker process for each channel existent in the DB
    hardcoded_channel_id = 500
    children = [
      {ChannelBroker, [hardcoded_channel_id]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
