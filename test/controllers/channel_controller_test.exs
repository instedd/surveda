defmodule Ask.ChannelControllerTest do
  use Ask.ConnCase

  @valid_attrs %{name: "some content", provider: "some content", settings: %{}, type: "some content"}
  @invalid_attrs %{name: ""}

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")
    {:ok, conn: conn, user: user}
  end

  describe "index" do

    test "check index response is 200", %{conn: conn} do
      conn = get conn, channel_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end

    test "list only channels from the current user", %{conn: conn, user: user} do
      channel = insert(:channel, user: user)
      channel_map = %{"id"       => channel.id,
                      "name"     => channel.name,
                      "provider" => channel.provider,
                      "settings" => channel.settings,
                      "type"     => channel.type,
                      "user_id"  => channel.user_id}
      insert(:channel)
      conn = get conn, channel_path(conn, :index)
      assert json_response(conn, 200)["data"] == [channel_map]
    end

  end

  describe "show" do

    test "shows chosen resource", %{conn: conn, user: user} do
      channel = insert(:channel, user: user)
      conn = get conn, channel_path(conn, :show, channel)
      assert json_response(conn, 200)["data"] == %{"id" => channel.id,
                                                   "user_id" => user.id,
                                                   "name" => channel.name,
                                                   "type" => channel.type,
                                                   "provider" => channel.provider,
                                                   "settings" => channel.settings}
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, channel_path(conn, :show, -1)
      end
    end

    test "forbid access to channels from other users", %{conn: conn} do
      channel = insert(:channel)
      assert_error_sent :forbidden, fn ->
        get conn, channel_path(conn, :show, channel)
      end
    end

  end

end
