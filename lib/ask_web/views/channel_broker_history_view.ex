defmodule AskWeb.ChannelBrokerHistoryView do
  use AskWeb, :view

  def render("index.json", %{channel_broker_histories: channel_broker_histories}) do
    %{data: render_many(channel_broker_histories, AskWeb.ChannelBrokerHistoryView, "index.json")}
  end

  def render("index.json", %{channel_broker_history: channel_broker_history}) do
    %{
      id: channel_broker_history |> elem(0),
      channel_id: channel_broker_history |> elem(1),
      instruction: channel_broker_history |> elem(2),
      parameters: channel_broker_history |> elem(3),
      active_contacts: channel_broker_history |> elem(4),
      contacts_queue_ids: channel_broker_history |> elem(5),
      inserted_at: channel_broker_history |> elem(6),
      updated_at: channel_broker_history |> elem(7)
    }
  end
end
