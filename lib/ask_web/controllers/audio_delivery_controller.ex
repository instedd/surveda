defmodule AskWeb.AudioDeliveryController do
  use AskWeb, :controller

  alias Ask.Audio

  def show(conn, %{"id" => uuid}) do
    audio = Repo.get_by!(Audio, uuid: uuid)

    conn
    |> put_resp_header("content-type", Audio.mime_type(audio))
    |> put_resp_header("content-disposition", "attachment; filename=#{audio.filename}")
    |> put_cache_headers()
    |> send_resp(200, audio.data)
  end
end
