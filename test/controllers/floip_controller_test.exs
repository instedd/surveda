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
      conn = get conn, "#{project_survey_packages_path(conn, :index, project.id, survey.id)}?foo=bar"

      assert json_response(conn, 200) == Ask.FloipView.render("index.json", %{
        packages: [ survey.floip_package_id ],
        self_link: "#{project_survey_packages_url(conn, :index, project.id, survey.id)}?foo=bar"
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

    test "injects a self referential link to the view", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: "running", floip_package_id: "foo", started_at: DateTime.utc_now)

      conn = get conn, "#{project_survey_package_descriptor_path(conn, :show, project.id, survey.id, survey.floip_package_id)}?foo=bar"

      assert json_response(conn, 200) == Ask.FloipView.render("show.json", %{
        self_link: "#{project_survey_package_descriptor_url(conn, :show, project.id, survey.id, survey.floip_package_id)}?foo=bar",
        descriptor: FloipPackage.descriptor(survey, project_survey_package_responses_url(conn, :responses, project.id, survey.id, "foo"))
      })
    end

    test "shows a package descriptor", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: "running", floip_package_id: "foo", started_at: DateTime.utc_now)

      conn = get conn, project_survey_package_descriptor_path(conn, :show, project.id, survey.id, survey.floip_package_id)

      assert json_response(conn, 200) == Ask.FloipView.render("show.json", %{
        self_link: project_survey_package_descriptor_url(conn, :show, project.id, survey.id, "foo"),
        descriptor: FloipPackage.descriptor(survey, project_survey_package_responses_url(conn, :responses, project.id, survey.id, survey.floip_package_id))
      })
    end
  end

  describe "responses" do
    test "injects a self referential link to the view", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: "running", floip_package_id: "foo", started_at: DateTime.utc_now)

      requested_path = "#{project_survey_package_responses_path(conn, :responses, project.id, survey.id, "foo")}?foo=bar"
      conn = get(conn, requested_path)

      corresponding_descriptor_url = project_survey_package_descriptor_url(conn, :show, project.id, survey.id, "foo")

      {responses, _, _ } = FloipPackage.responses(survey)

      assert json_response(conn, 200) == Ask.FloipView.render("responses.json",
        descriptor_link: corresponding_descriptor_url,
        self_link: "#{project_survey_package_responses_url(conn, :responses, project.id, survey.id, "foo")}?foo=bar",
        next_link: nil,
        previous_link: nil,
        id: FloipPackage.id(survey),
        responses: responses
      )
    end

    test "injects links for next page and previous page", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: "running", floip_package_id: "foo", started_at: DateTime.utc_now)

      respondent = insert(:respondent, survey: survey, hashed_number: "1234")

      for i <- 1..50 do
        response_minute = String.pad_leading(i |> Integer.to_string, 2, "0")
        insert(:response,
          respondent: respondent,
          field_name: "Exercises #{i}",
          value: "Yes",
          inserted_at: DateTime.from_iso8601("2000-01-01T00:#{response_minute}:00Z") |> elem(1),
          id: i)
      end

      base_path = project_survey_package_responses_path(conn, :responses, project.id, survey.id, "foo")

      base_query_params = "?"

      start_timestamp = "2000-01-01T00:00:00Z"
      start_timestamp_filter = "filter[start-timestamp]=#{start_timestamp}"

      end_timestamp = "2000-01-01T00:59:00Z"
      end_timestamp_filter = "&filter[end-timestamp]=#{end_timestamp}"

      page_size = "&page[size]=5"

      full_query_params = "#{base_query_params}#{start_timestamp_filter}#{end_timestamp_filter}#{page_size}"

      conn = get(conn, "#{base_path}#{full_query_params}")

      base_url = project_survey_package_responses_url(conn, :responses, project.id, survey.id, "foo")
      links = json_response(conn, 200)["data"]["relationships"]["links"]

      # Highlights of this assertion:
      # -self_link preserves the originally requested URL
      # -next_link adds a "page[afterCursor]" param that specifies the last response id included in
      #  this request (it's 5 because response id's go from 1 to 50, page[size]=5 and there wasn't a page[afterCursor] in the original request)
      # -previous_link adds a "page[beforeCursor]" param that specifies the first response id included in
      #  this request (it's 1 because response id's go from 1 to 50, and there wasn't a page[afterCursor] in the original request)
      assert links["next"] == "#{base_url}#{full_query_params}&page[afterCursor]=5"
      assert links["previous"] == "#{base_url}#{full_query_params}&page[beforeCursor]=1"
    end

    test "happy path", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: "running", floip_package_id: "foo", started_at: DateTime.utc_now)

      requested_path = project_survey_package_responses_path(conn, :responses, project.id, survey.id, "foo")
      conn = get(conn, requested_path)

      corresponding_descriptor_url = project_survey_package_descriptor_url(conn, :show, project.id, survey.id, "foo")

      {responses, _, _ } = FloipPackage.responses(survey)

      assert json_response(conn, 200) == Ask.FloipView.render("responses.json",
        descriptor_link: corresponding_descriptor_url,
        self_link: project_survey_package_responses_url(conn, :responses, project.id, survey.id, "foo"),
        next_link: nil,
        previous_link: nil,
        id: FloipPackage.id(survey),
        responses: responses
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
