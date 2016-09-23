defmodule Ask.ChannelControllerTest do
  use Ask.ConnCase

  alias Ask.Channel
  @valid_attrs %{name: "some content", provider: "some content", settings: %{}, type: "some content"}
  @invalid_attrs %{name: ""}

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")
    {:ok, conn: conn, user: user}
  end

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
    conn = get conn, channel_path(conn, :show, channel)
    assert json_response(conn, :forbidden)["error"] == "Forbidden"
  end

  test "creates and renders resource when data is valid", %{conn: conn, user: user} do
    conn = post conn, channel_path(conn, :create), channel: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    channel = Repo.get_by(Channel, @valid_attrs)
    assert channel
    assert channel.user_id == user.id
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, channel_path(conn, :create), channel: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn, user: user} do
    channel = insert(:channel, user: user)
    conn = put conn, channel_path(conn, :update, channel), channel: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Channel, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn, user: user} do
    channel = insert(:channel, user: user)
    conn = put conn, channel_path(conn, :update, channel), channel: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "forbid update to channel from other user", %{conn: conn} do
    channel = insert(:channel)
    conn = put conn, channel_path(conn, :update, channel), channel: @invalid_attrs
    assert json_response(conn, :forbidden)["error"] == "Forbidden"
  end

  test "deletes chosen resource", %{conn: conn, user: user} do
    channel = insert(:channel, user: user)
    conn = delete conn, channel_path(conn, :delete, channel)
    assert response(conn, 204)
    refute Repo.get(Channel, channel.id)
  end

  test "forbid to delete channel from other user", %{conn: conn} do
    channel = insert(:channel)
    conn = delete conn, channel_path(conn, :delete, channel)
    assert json_response(conn, :forbidden)["error"] == "Forbidden"
  end
end
