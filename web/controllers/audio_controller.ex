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

    conn
    |> put_resp_content_type("audio/mpeg")
    |> put_resp_header("content-disposition", "attachment; filename=#{audio.filename}")
    |> send_resp(200, audio.data)
  end
end
