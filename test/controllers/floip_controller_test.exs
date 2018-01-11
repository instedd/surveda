defmodule Ask.FloipControllerTest do
  use Ask.ConnCase
  use Ask.TestHelpers

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")
    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "check index response is 200", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      conn = get conn, project_survey_packages_path(conn, :index, project.id, survey.id)
      assert json_response(conn, 200)
    end

    test "check accepts json-api request", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      conn = conn |> put_req_header("accept", "application/vnd.api+json")
      conn = get conn, project_survey_packages_path(conn, :index, project.id, survey.id)
      assert json_response(conn, 200)
    end

    test "does not leak surveys that dont belong to user", %{conn: conn, user: user} do
      user2 = insert(:user)
      project = create_project_for_user(user2)
      survey = insert(:survey, project: project)

      assert_error_sent :forbidden, fn ->
        get conn, project_survey_packages_path(conn, :index, project.id, survey.id)
      end
    end

    test "injects a self referential link to the view", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: "running")

      conn = conn |> put_req_header("accept", "application/vnd.api+json")
      conn = get conn, project_survey_packages_path(conn, :index, project.id, survey.id)

      assert json_response(conn, 200) == Ask.FloipView.render("index.json", %{
        packages: [ survey.floip_package_id ],
        self_link: project_survey_packages_url(conn, :index, project.id, survey.id)
      })
    end

    # test "list only channels from the current user", %{conn: conn, user: user} do
    #   channel = insert(:channel, user: user)
    #   channel_map = %{"id"       => channel.id,
    #                   "name"     => channel.name,
    #                   "provider" => channel.provider,
    #                   "settings" => channel.settings,
    #                   "type"     => channel.type,
    #                   "user_id"  => channel.user_id,
    #                   "channelBaseUrl" => channel.base_url}
    #   insert(:channel)
    #   conn = get conn, channel_path(conn, :index)
    #   assert json_response(conn, 200)["data"] == [channel_map]
    # end

  end
end
