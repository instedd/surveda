defmodule Ask.Runtime.ChannelBrokerSupervisor do
  alias Ask.Runtime.{ChannelBroker, ChannelBrokerSupervisor}
  alias Ask.{Channel, Repo}
  import Ecto.Query
  use Supervisor

  def start_link() do
    ChannelBrokerSupervisor.start_link([])
  end

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    query = from ch in Channel,
      select: ch.id
    channel_ids = Repo.all(query)

    children = Enum.map(channel_ids, fn channel_id ->
      Supervisor.child_spec({ChannelBroker, [channel_id]}, id: "channel_broker_#{channel_id}")
    end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
