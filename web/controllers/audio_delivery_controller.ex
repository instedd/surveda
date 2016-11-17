defmodule Ask.AudioDeliveryController do
  use Ask.Web, :controller

  alias Ask.Audio

  def show(conn, %{"id" => uuid}) do
    audio = Repo.get_by!(Audio, uuid: uuid)

    conn
    |> put_resp_header("content-type", Audio.mime_type(audio))
    |> put_resp_header("content-disposition", "attachment; filename=#{audio.filename}")
    |> send_resp(200, audio.data)
  end
end
