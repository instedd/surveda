defmodule Ask.AudioController do
  use Ask.Web, :api_controller
  alias Ask.Logger

  alias Ask.Audio

  def create(conn, %{"file" => file_upload}) do
    upload_changeset = Audio.upload_changeset(file_upload)
    result = if upload_changeset.valid? do
      new_audio = Audio.params_from_converted_upload(file_upload)
      changeset = Audio.changeset(%Audio{}, new_audio)
      Repo.insert(changeset)
    else
      {:error, upload_changeset}
    end

    case result do
      {:ok, audio} ->
        conn
        |> put_status(:created)
        |> render("show.json", audio: %{id: audio.uuid})
      {:error, changeset} ->
        Logger.warn "Error during audio uploading: #{inspect changeset}"
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
    |> send_resp(200, audio.data)
  end
end
