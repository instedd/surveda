defmodule AskWeb.AudioDeliveryControllerTest do
  use AskWeb.ConnCase

  setup %{conn: conn} do
    user = insert(:user)

    conn =
      conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn, user: user}
  end

  describe "show" do
    test "returns the audio file with long cache expiry", %{conn: conn} do
      audio = insert(:audio)
      conn = get(conn, audio_path(conn, :show, audio.uuid))

      assert conn.status == 200
      assert conn.resp_body == File.read!("test/fixtures/audio.mp3")
      assert get_resp_header(conn, "cache-control") == ["public, max-age=31556926, immutable"]
    end

    test "returns 404 when the file doesn't exist", %{conn: conn} do
      assert_error_sent 404, fn ->
        get(conn, audio_path(conn, :show, 1234))
      end
    end
  end
end
