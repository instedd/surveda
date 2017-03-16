defmodule Ask.ChannelController do
  use Ask.Web, :api_controller

  alias Ask.Channel

  def index(conn, _params) do
    channels = conn
    |> current_user
    |> assoc(:channels)
    |> Repo.all

    render(conn, "index.json", channels: channels)
  end

  def show(conn, %{"id" => id}) do
    channel = Channel
    |> Repo.get!(id)
    |> authorize_channel(conn)

    render(conn, "show.json", channel: channel)
  end

  def delete(conn, %{"id" => id}) do
    Channel
    |> Repo.get!(id)
    |> authorize_channel(conn)
    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    |> Repo.delete!()

    send_resp(conn, :no_content, "")
  end
end
