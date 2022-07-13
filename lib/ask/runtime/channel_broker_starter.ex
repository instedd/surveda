defmodule Ask.Runtime.ChannelBrokerStarter do
  alias Ask.{Channel, Repo}
  alias Ask.Runtime.ChannelBrokerSupervisor
  import Ecto.Query
  use Supervisor

  def start_link() do
    start_link([])
  end

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    # Inspired by: https://elixirforum.com/t/understanding-dynamicsupervisor-no-initial-children/14938/2
    children = [
      supervisor(ChannelBrokerSupervisor, []),
      {
        Task,
        fn ->
          query =
            from ch in Channel,
              select: [ch.id, ch.settings]

          channels = Repo.all(query)

          Enum.each(channels, fn [channel_id, settings] ->
            {:ok, _pid} = ChannelBrokerSupervisor.start_child(channel_id, settings)
          end)
        end
      }
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
