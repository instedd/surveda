defmodule Ask.AudioController do
  use Ask.Web, :api_controller

  alias Ask.Audio

  def create(conn, %{"file" => file_upload}) do
    {:ok, file_content} = File.read(file_upload.path)
    new_audio =
      %{
        data: file_content,
        filename: file_upload.filename
      }
    changeset = Audio.changeset(%Audio{}, new_audio)

    case Repo.insert(changeset) do
      {:ok, audio} ->
        conn
        |> put_status(:created)
        |> render("show.json", audio: %{id: audio.id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    audio = Repo.get!(Audio, id)

    conn
    |> put_resp_content_type("audio/mpeg")
    |> put_resp_header("content-disposition", "attachment; filename=#{audio.filename}")
    |> send_resp(200, audio.data)
  end

end
