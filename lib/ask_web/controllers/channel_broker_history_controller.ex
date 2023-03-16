defmodule AskWeb.ChannelBrokerHistoryController do
  use AskWeb, :api_controller

  alias Ask.{Channel, Project, Logger}
  alias Ask.Runtime.ChannelBrokerHistory

  def index(conn, %{"channel_id" => channel_id}) do
    channel_broker_histories =
      Repo.all(
        from r in ChannelBrokerHistory,
          where: r.channel_id == ^channel_id,
          select:
            {r.id, r.channel_id, r.instruction, [], r.active_contacts, r.contacts_queue_ids,
             r.inserted_at, r.updated_at},
          order_by: [desc: r.inserted_at],
          limit: 1000
      )

    render(conn, "index.json", channel_broker_histories: channel_broker_histories)
  end
end
