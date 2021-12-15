defmodule Ask.AudioControllerTest do

  use Ask.ConnCase

  alias Ask.{Audio, AudioChecker}

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
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
      audio_count = Audio |> Repo.all |> Enum.count
      assert audio_count == 0
      post conn, audio_path(conn, :create), file: file
      audio_count = Audio |> Repo.all |> Enum.count
      assert audio_count == 1

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

    test "WAV: when data is valid saves the audio as MP3", %{conn: conn} do
      file = %Plug.Upload{path: "test/fixtures/audio.wav", filename: "test1.wav"}
      audio_count = Audio |> Repo.all |> Enum.count
      assert audio_count == 0
      post conn, audio_path(conn, :create), file: file
      audio_count = Audio |> Repo.all |> Enum.count
      assert audio_count == 1

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

    test "when the data is invalid it returns a 422", %{conn: conn} do
      file = %Plug.Upload{path: "test/fixtures/invalid_audio.csv", filename: "test1.csv"}
      conn = post conn, audio_path(conn, :create), file: file

      assert conn.status == 422
    end

    test "doesn't save if the file is of an invalid type", %{conn: conn} do
      file = %Plug.Upload{path: "test/fixtures/invalid_audio.csv", filename: "test1.csv"}
      audio_count = Audio |> Repo.all |> Enum.count
      assert audio_count == 0
      post conn, audio_path(conn, :create), file: file
      audio_count = Audio |> Repo.all |> Enum.count
      assert audio_count == 0
    end

    test "returns a validation error if the file is of an invalid type", %{conn: conn} do
      file = %Plug.Upload{path: "test/fixtures/invalid_audio.csv", filename: "test1.csv"}
      conn = post conn, audio_path(conn, :create), file: file

      assert Enum.at(json_response(conn, 422)["errors"]["filename"], 0) == "Invalid file type. Allowed types are MP3 and WAV."
    end

  end

  describe "show" do
    test "returns the file with long cache expiry", %{conn: conn} do
      audio = insert(:audio)
      conn = get conn, audio_path(conn, :show, audio.uuid)

      assert conn.status == 200
      assert conn.resp_body == File.read!("test/fixtures/audio.mp3")
      assert get_resp_header(conn, "cache-control") == ["public, max-age=31556926, immutable"]
    end

    test "returns 404 when the file doesn't exist", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, audio_path(conn, :show, 1234)
      end
    end
  end

end
