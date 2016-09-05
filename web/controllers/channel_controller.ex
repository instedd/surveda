defmodule Ask.ChannelController do
  use Ask.Web, :api_controller

  alias Ask.Channel

  def index(conn, _params) do
    channels = Repo.all(from c in Channel, where: c.user_id == ^current_user(conn).id)
    render(conn, "index.json", channels: channels)
  end

  def create(conn, %{"channel" => channel_params}) do
    changeset = Channel.changeset(%Channel{user_id: current_user(conn).id}, channel_params)

    case Repo.insert(changeset) do
      {:ok, channel} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", channel_path(conn, :show, channel))
        |> render("show.json", channel: channel)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    channel = Repo.get!(Channel, id)
    if channel.user_id == current_user(conn).id do
      render(conn, "show.json", channel: channel)
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Forbidden"})
    end
  end

  def update(conn, %{"id" => id, "channel" => channel_params}) do
    channel = Repo.get!(Channel, id)

    if channel.user_id == current_user(conn).id do
      changeset = Channel.changeset(channel, channel_params)

      case Repo.update(changeset) do
        {:ok, channel} ->
          render(conn, "show.json", channel: channel)
        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(Ask.ChangesetView, "error.json", changeset: changeset)
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Forbidden"})
    end
  end

  def delete(conn, %{"id" => id}) do
    channel = Repo.get!(Channel, id)

    if channel.user_id == current_user(conn).id do
      # Here we use delete! (with a bang) because we expect
      # it to always work (and if it does not, it will raise).
      Repo.delete!(channel)

      send_resp(conn, :no_content, "")
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Forbidden"})
    end
  end
end
