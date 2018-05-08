defmodule Ask.ChannelController do
  use Ask.Web, :api_controller

  alias Ask.{Channel, Project, Logger}

  def index(conn, %{"project_id" => project_id}) do
    channels = conn
    |> load_project(project_id)
    |> assoc(:channels)
    |> Repo.all

    render(conn, "index.json", channels: channels |> Repo.preload(:projects))
  end

  def index(conn, _params) do
    channels = conn
    |> current_user
    |> assoc(:channels)
    |> Repo.all
    |> Repo.preload(:projects)

    render(conn, "index.json", channels: channels)
  end

  def show(conn, %{"id" => id}) do
    channel = Channel
    |> Repo.get!(id)
    |> authorize_channel(conn)
    |> Repo.preload(:projects)

    render(conn, "show.json", channel: channel)
  end

  def update(conn, %{"id" => id, "channel" => channel_params}) do
    channel =
      Channel
      |> Repo.get!(id)
      |> authorize_channel(conn)
      |> Repo.preload([:projects])

    changeset =
      channel
      |> Channel.changeset(channel_params)
      |> update_projects(channel_params, conn)

    case Repo.update(changeset, force: Map.has_key?(changeset.changes, :projects)) do
      {:ok, channel} ->
        render(conn, "show.json", channel: channel |> Repo.preload(:projects))

      {:error, changeset} ->
        Logger.warn("Error when updating channel: #{inspect(changeset)}")

        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp update_projects(changeset, %{"projects" => project_ids}, conn) do
    projects_changeset =
      Enum.map(project_ids, fn id ->
        Repo.get!(Project, id) |> authorize(conn) |> change
      end)

    changeset
    |> put_assoc(:projects, projects_changeset)
  end

  defp update_projects(changeset, _, _) do
    changeset
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
