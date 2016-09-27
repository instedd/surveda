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

  def create(conn, %{"channel" => channel_params}) do
    changeset = conn
    |> current_user
    |> build_assoc(:channels)
    |> Channel.changeset(channel_params)

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
    channel = Channel
    |> Repo.get!(id)
    |> authorize(conn)

    render(conn, "show.json", channel: channel)
  end

  def update(conn, %{"id" => id, "channel" => channel_params}) do
    changeset = Channel
    |> Repo.get!(id)
    |> authorize(conn)
    |> Channel.changeset(channel_params)

    case Repo.update(changeset) do
      {:ok, channel} ->
        render(conn, "show.json", channel: channel)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    Channel
    |> Repo.get!(id)
    |> authorize(conn)
    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    |> Repo.delete!()

    send_resp(conn, :no_content, "")
  end
end
