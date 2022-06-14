defmodule AskWeb.ChannelControllerTest do
  use AskWeb.ConnCase
  use Ask.TestHelpers

  setup %{conn: conn} do
    user = insert(:user)

    conn =
      conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")

    {:ok, _} = Ask.Runtime.ChannelStatusServer.start_link()
    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "check index response is 200", %{conn: conn} do
      conn = get(conn, channel_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end

    test "list only channels from the current user", %{conn: conn, user: user} do
      channel = insert(:channel, user: user)

      channel_map = %{
        "id" => channel.id,
        "name" => channel.name,
        "provider" => channel.provider,
        "settings" => channel.settings,
        "patterns" => [],
        "type" => channel.type,
        "user_id" => channel.user_id,
        "projects" => [],
        "channelBaseUrl" => channel.base_url,
        "status_info" => %{"status" => "unknown"},
        "userEmail" => user.email
      }

      insert(:channel)
      conn = get(conn, channel_path(conn, :index))
      assert json_response(conn, 200)["data"] == [channel_map]
    end

    test "list only channels for a given project", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      user2 = insert(:user)

      channel1 = insert(:channel, user: user, projects: [project])
      channel2 = insert(:channel, user: user2, projects: [project])

      insert(:channel, user: user)
      insert(:channel, user: user2)

      channel_map1 = %{
        "id" => channel1.id,
        "name" => channel1.name,
        "provider" => channel1.provider,
        "settings" => channel1.settings,
        "patterns" => [],
        "type" => channel1.type,
        "user_id" => channel1.user_id,
        "projects" => [project.id],
        "channelBaseUrl" => channel1.base_url,
        "status_info" => nil,
        "userEmail" => user.email
      }

      channel_map2 = %{
        "id" => channel2.id,
        "name" => channel2.name,
        "provider" => channel2.provider,
        "settings" => channel2.settings,
        "patterns" => [],
        "type" => channel2.type,
        "user_id" => channel2.user_id,
        "projects" => [project.id],
        "channelBaseUrl" => channel2.base_url,
        "status_info" => nil,
        "userEmail" => user2.email
      }

      conn = get(conn, project_channel_path(conn, :index, project.id))
      assert json_response(conn, 200)["data"] == [channel_map1, channel_map2]
    end
  end

  describe "show" do
    test "shows chosen resource", %{conn: conn, user: user} do
      channel = insert(:channel, user: user)
      conn = get(conn, channel_path(conn, :show, channel))

      assert json_response(conn, 200)["data"] == %{
               "id" => channel.id,
               "user_id" => user.id,
               "name" => channel.name,
               "type" => channel.type,
               "provider" => channel.provider,
               "settings" => channel.settings,
               "patterns" => [],
               "projects" => [],
               "channelBaseUrl" => channel.base_url,
               "status_info" => %{"status" => "unknown"},
               "userEmail" => user.email
             }
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent 404, fn ->
        get(conn, channel_path(conn, :show, -1))
      end
    end

    test "forbid access to channels from other users", %{conn: conn} do
      channel = insert(:channel)

      assert_error_sent :forbidden, fn ->
        get(conn, channel_path(conn, :show, channel))
      end
    end
  end

  describe "update" do
    test "share channel with projects", %{conn: conn, user: user} do
      project1 = create_project_for_user(user)
      project2 = create_project_for_user(user)

      channel = insert(:channel, user: user)

      conn =
        put conn, channel_path(conn, :update, channel),
          channel: %{projects: [project1.id, project2.id]}

      assert json_response(conn, 200)["data"]["projects"] == [project1.id, project2.id]
    end

    test "don't share channel with another user's project", %{conn: conn, user: user} do
      project1 = create_project_for_user(user)

      user2 = insert(:user)
      project2 = create_project_for_user(user2)

      channel = insert(:channel, user: user)

      assert_error_sent :forbidden, fn ->
        put conn, channel_path(conn, :update, channel),
          channel: %{projects: [project1.id, project2.id]}
      end
    end

    test "update patterns", %{conn: conn, user: user} do
      channel = insert(:channel, user: user)

      patterns = [
        %{"input" => "123XX", "output" => "0XX"},
        %{"input" => "222XX", "output" => "0XX"}
      ]

      conn = put conn, channel_path(conn, :update, channel), channel: %{patterns: patterns}

      assert json_response(conn, 200)["data"]["patterns"] == patterns
    end
  end

  describe "create" do
    test "create channel", %{conn: conn, user: user} do
      user_id = user.id
      insert(:oauth_token, user: user)

      conn =
        post conn, channel_path(conn, :create),
          provider: "test",
          base_url: "http://test.com",
          channel: %{"id" => 123}

      channel =
        user
        |> assoc(:channels)
        |> Repo.one!()

      assert %Ask.Channel{
               user_id: ^user_id,
               provider: "test",
               base_url: "http://test.com",
               type: "ivr",
               name: "test",
               settings: %{"id" => 123}
             } = channel

      assert json_response(conn, 200)["data"] == %{
               "id" => channel.id,
               "user_id" => user.id,
               "name" => channel.name,
               "type" => channel.type,
               "provider" => channel.provider,
               "settings" => channel.settings,
               "channelBaseUrl" => channel.base_url,
               "projects" => [],
               "patterns" => [],
               "status_info" => nil,
               "userEmail" => user.email
             }
    end

    test "cannot create channel if the authorization doesn't exist", %{conn: conn} do
      assert_error_sent :forbidden, fn ->
        post conn, channel_path(conn, :create),
          provider: "test",
          base_url: "http://test.com",
          channel: %{"id" => 123}
      end
    end
  end
end
