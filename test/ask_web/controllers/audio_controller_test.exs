defmodule AskWeb.AudioControllerTest do
  use AskWeb.ConnCase

  alias Ask.{Audio, AudioChecker}

  setup %{conn: conn} do
    user = insert(:user)

    conn =
      conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn, user: user}
  end

  describe "create" do
    test "when the data is valid it returns a 201", %{conn: conn} do
      file = %Plug.Upload{path: "test/fixtures/audio.mp3", filename: "test1.mp3"}
      conn = post conn, audio_path(conn, :create), file: file

      assert conn.status == 201
    end

    test "MP3: when data is valid saves the audio", %{conn: conn} do
      file = %Plug.Upload{path: "test/fixtures/audio.mp3", filename: "test1.mp3"}
      post conn, audio_path(conn, :create), file: file
      assert Repo.one(from p in Audio, select: count()) == 1

      audio = Repo.one(Audio)
      assert audio.filename == "test1.mp3"
      assert AudioChecker.get_audio_format(audio.data, "mp3") == "mp3"
    end

    test "MP3: when data is valid returns its uuid", %{conn: conn} do
      file = %Plug.Upload{path: "test/fixtures/audio.mp3", filename: "test1.mp3"}
      conn = post conn, audio_path(conn, :create), file: file

      uuid = Repo.one(Audio).uuid
      assert json_response(conn, 201)["data"] == %{"id" => uuid}
    end

    test "MP3 with WAV extension: saves as MP3", %{conn: conn} do
      File.copy("test/fixtures/audio.mp3", "test/fixtures/mpeg.wav")
      try do
        file = %Plug.Upload{path: "test/fixtures/mpeg.wav", filename: "mpeg.wav"}
        conn = post conn, audio_path(conn, :create), file: file
        assert conn.status == 201
      after
        File.rm("test/fixtures/mpeg.wav")
      end
      %{filename: "mpeg.mp3"} = Repo.one(Audio)
    end

    test "WAV: when data is valid saves the audio as MP3", %{conn: conn} do
      file = %Plug.Upload{path: "test/fixtures/audio.wav", filename: "test1.wav"}
      post conn, audio_path(conn, :create), file: file
      assert Repo.one(from p in Audio, select: count()) == 1

      audio = Repo.one(Audio)
      assert audio.filename == "test1.mp3"
      assert AudioChecker.get_audio_format(audio.data, "mp3") == "mp3"
    end

    test "WAV: when data is valid returns its uuid", %{conn: conn} do
      file = %Plug.Upload{path: "test/fixtures/audio.wav", filename: "test1.wav"}
      conn = post conn, audio_path(conn, :create), file: file

      uuid = Repo.one(Audio).uuid
      assert json_response(conn, 201)["data"] == %{"id" => uuid}
    end

    test "WAV with MP3 extension: saves as MP3", %{conn: conn} do
      File.copy("test/fixtures/audio.wav", "test/fixtures/wave.mp3")
      try do
        file = %Plug.Upload{path: "test/fixtures/wave.mp3", filename: "wave.mp3"}
        conn = post conn, audio_path(conn, :create), file: file
        assert conn.status == 201
      after
        File.rm("test/fixtures/wave.mp3")
      end
      %{filename: "wave.mp3"} = Repo.one(Audio)
    end

    test "returns a validation error if the file is of an invalid type", %{conn: conn} do
      file = %Plug.Upload{path: "test/fixtures/invalid_audio.csv", filename: "test1.csv"}
      conn = post conn, audio_path(conn, :create), file: file

      %{"errors" => errors} = json_response(conn, 422)
      assert errors["filename"] == ["Invalid file. Allowed types are MP3 and WAV."]
      assert Repo.one(from p in Audio, select: count()) == 0
    end

    test "returns a validation error if the file has invalid audio contents", %{conn: conn} do
      file = %Plug.Upload{path: "test/fixtures/invalid.mp3", filename: "invalid.mp3"}
      conn = post conn, audio_path(conn, :create), file: file

      %{"errors" => errors} = json_response(conn, 422)
      assert errors["filename"] == ["Invalid file. Allowed types are MP3 and WAV."]
      assert Repo.one(from p in Audio, select: count()) == 0
    end
  end

  describe "show" do
    test "returns the file with long cache expiry", %{conn: conn} do
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

  describe "tts" do
    test "transforms text to speech", %{conn: conn} do
      conn = get(conn, audio_path(conn, :tts, text: "lorem ipsum"))

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["audio/x-wav"]
      assert get_resp_header(conn, "cache-control") == ["public, max-age=31556926, immutable"]
      assert byte_size(conn.resp_body) > 0
    end
  end
end
