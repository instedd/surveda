defmodule Ask.AudioController do
  use Ask.Web, :api_controller

  alias Ask.Audio

  def create(conn, %{"file" => file_upload}) do
    {:ok, file_content} = File.read(file_upload.path)
    new_audio =
      %{
        uuid: Ecto.UUID.generate,
        filename: file_upload.filename,
        data: file_content
      }
    changeset = Audio.changeset(%Audio{}, new_audio)

    case Repo.insert(changeset) do
      {:ok, audio} ->
        conn
        |> put_status(:created)
        |> render("show.json", audio: %{id: audio.uuid})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => uuid}) do
    audio = Repo.get_by!(Audio, uuid: uuid)

    # Send raw audio. If later we want to set a filename, so it
    # can be downloaded, be careful to use a valid filename
    # (one that doesn't have commas or strange characters)
    conn
    # Expires in one year ( recommended by RFC 2616: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.21 )
    |> put_resp_header("cache-control", "max-age=31556926")
    |> send_resp(200, audio.data)
  end
end
