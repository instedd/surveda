defmodule Ask.FloipControllerTest do
  use Ask.ConnCase
  use Ask.TestHelpers

  alias Ask.FloipPackage

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

    test "does not leak surveys that dont belong to user", %{conn: conn, user: _user} do
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
  end

  describe "show" do
    test "does not leak packages that dont belong to user", %{conn: conn, user: _user} do
      user2 = insert(:user)
      project = create_project_for_user(user2)
      survey = insert(:survey, project: project, state: "running", floip_package_id: "foo")

      assert_error_sent :forbidden, fn ->
        get conn, project_survey_package_descriptor_path(conn, :show, project.id, survey.id, survey.floip_package_id)
      end
    end

    test "ensures provided package id is correct", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: "running", floip_package_id: "foo")

      assert_error_sent :forbidden, fn ->
        get conn, project_survey_package_descriptor_path(conn, :show, project.id, survey.id, "bar")
      end
    end

    test "ensures provided package id belongs to running or terminated survey", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: "not_ready", floip_package_id: "foo")

      assert_error_sent :forbidden, fn ->
        get conn, project_survey_package_descriptor_path(conn, :show, project.id, survey.id, "foo")
      end
    end

    test "shows a package descriptor", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: "running", floip_package_id: "foo", started_at: Timex.Ecto.DateTime.autogenerate)

      conn = get conn, project_survey_package_descriptor_path(conn, :show, project.id, survey.id, survey.floip_package_id)

      assert json_response(conn, 200) == Ask.FloipView.render("show.json", %{
        self_link: project_survey_package_descriptor_url(conn, :show, project.id, survey.id, "foo"),
        responses_link: project_survey_package_responses_url(conn, :responses, project.id, survey.id, "foo"),
        survey: survey
      })
    end
  end

  describe "responses" do
    test "happy path", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: "running", floip_package_id: "foo", started_at: Timex.Ecto.DateTime.autogenerate)

      requested_path = project_survey_package_responses_path(conn, :responses, project.id, survey.id, "foo")
      conn = get(conn, requested_path)

      corresponding_descriptor_url = project_survey_package_descriptor_url(conn, :show, project.id, survey.id, "foo")

      assert json_response(conn, 200) == Ask.FloipView.render("responses.json",
        descriptor_link: corresponding_descriptor_url,
        self_link: requested_path,
        survey: survey,
        responses: FloipPackage.responses(survey, requested_path)
      )
    end

    test "does not leak packages that dont belong to user", %{conn: conn, user: _user} do
      user2 = insert(:user)
      project = create_project_for_user(user2)
      survey = insert(:survey, project: project, state: "running", floip_package_id: "foo")

      assert_error_sent :forbidden, fn ->
        get conn, project_survey_package_responses_path(conn, :responses, project.id, survey.id, "foo")
      end
    end

    test "ensures provided package id is correct", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: "running", floip_package_id: "foo")

      assert_error_sent :forbidden, fn ->
        get conn, project_survey_package_responses_path(conn, :responses, project.id, survey.id, "bar")
      end
    end

    test "ensures provided package id belongs to running or terminated survey", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: "not_ready", floip_package_id: "foo")

      assert_error_sent :forbidden, fn ->
        get conn, project_survey_package_responses_path(conn, :responses, project.id, survey.id, "foo")
      end
    end
  end
end
