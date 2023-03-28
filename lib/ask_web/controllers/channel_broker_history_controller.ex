defmodule AskWeb.ChannelBrokerHistoryController do
  use AskWeb, :api_controller

  alias Ask.Runtime.ChannelBrokerHistory

  def index(conn, %{"channel_id" => channel_id}) do
    channel_broker_histories =
      Repo.all(
        from r in ChannelBrokerHistory,
          where: r.channel_id == ^channel_id,
          select:
            {r.id, r.channel_id, r.instruction, r.active_contacts, r.contacts_queue_ids,
             r.inserted_at, r.updated_at, r.parameters},
          order_by: [desc: r.inserted_at],
          limit: 10000
      )

    render(conn, "index.json", channel_broker_histories: channel_broker_histories)
  end

  def show(conn, %{"channel_id" => channel_id, "id" => id}) do
    channel_broker_history =
      Repo.one(
        from r in ChannelBrokerHistory,
          where: r.channel_id == ^channel_id and r.id == ^id,
          select:
            {r.id, r.channel_id, r.instruction, r.parameters, r.active_contacts,
             r.contacts_queue_ids, r.inserted_at, r.updated_at}
      )

    render(conn, "show.json", channel_broker_history: channel_broker_history)
  end
end
