defmodule Ask.SurveyLinkControllerTest do
  use Ask.ConnCase
  use Ask.TestHelpers
  use Ask.DummySteps
  use Ask.MockTime

  alias Ask.{ShortLink, ActivityLog}

  setup %{conn: conn} do
    user = insert(:user)

    conn =
      conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn, user: user}
  end

  describe "download links" do
    test "results link generation", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      response = get(conn, project_survey_links_path(conn, :create, project, survey, "results"))

      link = ShortLink |> Repo.one()

      assert json_response(response, 200) == %{
               "name" => "survey/#{survey.id}/results",
               "url" => "#{Ask.Endpoint.url()}/link/#{link.hash}"
             }

      assert link.target ==
               "/api/v1/projects/#{project.id}/surveys/#{survey.id}/respondents/results?_format=csv"

      response = get(conn, project_survey_links_path(conn, :create, project, survey, "results"))

      assert json_response(response, 200) == %{
               "name" => "survey/#{survey.id}/results",
               "url" => "#{Ask.Endpoint.url()}/link/#{link.hash}"
             }

      assert ShortLink |> Repo.all() |> length == 1

      response = put(conn, project_survey_links_path(conn, :refresh, project, survey, "results"))

      new_link = ShortLink |> Repo.one()

      assert json_response(response, 200) == %{
               "name" => "survey/#{survey.id}/results",
               "url" => "#{Ask.Endpoint.url()}/link/#{new_link.hash}"
             }

      assert link.hash != new_link.hash
      assert link.target == new_link.target

      response =
        delete(conn, project_survey_links_path(conn, :delete, project, survey, "results"))

      assert response(response, 204)
      assert [] == ShortLink |> Repo.all()
    end

    test "incentives link generation", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      response =
        get(conn, project_survey_links_path(conn, :create, project, survey, "incentives"))

      link = ShortLink |> Repo.one()

      assert json_response(response, 200) == %{
               "name" => "survey/#{survey.id}/incentives",
               "url" => "#{Ask.Endpoint.url()}/link/#{link.hash}"
             }

      response =
        get(conn, project_survey_links_path(conn, :create, project, survey, "incentives"))

      assert json_response(response, 200) == %{
               "name" => "survey/#{survey.id}/incentives",
               "url" => "#{Ask.Endpoint.url()}/link/#{link.hash}"
             }

      assert ShortLink |> Repo.all() |> length == 1

      assert link.target ==
               "/api/v1/projects/#{project.id}/surveys/#{survey.id}/respondents/incentives?_format=csv"

      response =
        put(conn, project_survey_links_path(conn, :refresh, project, survey, "incentives"))

      new_link = ShortLink |> Repo.one()

      assert json_response(response, 200) == %{
               "name" => "survey/#{survey.id}/incentives",
               "url" => "#{Ask.Endpoint.url()}/link/#{new_link.hash}"
             }

      assert link.hash != new_link.hash
      assert link.target == new_link.target

      response =
        delete(conn, project_survey_links_path(conn, :delete, project, survey, "incentives"))

      assert response(response, 204)
      assert [] == ShortLink |> Repo.all()
    end

    test "interactions link generation", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      response =
        get(conn, project_survey_links_path(conn, :create, project, survey, "interactions"))

      link = ShortLink |> Repo.one()

      assert json_response(response, 200) == %{
               "name" => "survey/#{survey.id}/interactions",
               "url" => "#{Ask.Endpoint.url()}/link/#{link.hash}"
             }

      response =
        get(conn, project_survey_links_path(conn, :create, project, survey, "interactions"))

      assert json_response(response, 200) == %{
               "name" => "survey/#{survey.id}/interactions",
               "url" => "#{Ask.Endpoint.url()}/link/#{link.hash}"
             }

      assert ShortLink |> Repo.all() |> length == 1

      assert link.target ==
               "/api/v1/projects/#{project.id}/surveys/#{survey.id}/respondents/interactions?_format=csv"

      response =
        put(conn, project_survey_links_path(conn, :refresh, project, survey, "interactions"))

      new_link = ShortLink |> Repo.one()

      assert json_response(response, 200) == %{
               "name" => "survey/#{survey.id}/interactions",
               "url" => "#{Ask.Endpoint.url()}/link/#{new_link.hash}"
             }

      assert link.hash != new_link.hash
      assert link.target == new_link.target

      response =
        delete(conn, project_survey_links_path(conn, :delete, project, survey, "interactions"))

      assert response(response, 204)
      assert [] == ShortLink |> Repo.all()
    end

    test "disposition_history link generation", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      response =
        get(
          conn,
          project_survey_links_path(conn, :create, project, survey, "disposition_history")
        )

      link = ShortLink |> Repo.one()

      assert json_response(response, 200) == %{
               "name" => "survey/#{survey.id}/disposition_history",
               "url" => "#{Ask.Endpoint.url()}/link/#{link.hash}"
             }

      assert link.target ==
               "/api/v1/projects/#{project.id}/surveys/#{survey.id}/respondents/disposition_history?_format=csv"

      response =
        get(
          conn,
          project_survey_links_path(conn, :create, project, survey, "disposition_history")
        )

      assert json_response(response, 200) == %{
               "name" => "survey/#{survey.id}/disposition_history",
               "url" => "#{Ask.Endpoint.url()}/link/#{link.hash}"
             }

      assert ShortLink |> Repo.all() |> length == 1

      response =
        put(
          conn,
          project_survey_links_path(conn, :refresh, project, survey, "disposition_history")
        )

      new_link = ShortLink |> Repo.one()

      assert json_response(response, 200) == %{
               "name" => "survey/#{survey.id}/disposition_history",
               "url" => "#{Ask.Endpoint.url()}/link/#{new_link.hash}"
             }

      assert link.hash != new_link.hash
      assert link.target == new_link.target

      response =
        delete(
          conn,
          project_survey_links_path(conn, :delete, project, survey, "disposition_history")
        )

      assert response(response, 204)
      assert [] == ShortLink |> Repo.all()
    end

    test "forbids readers to create links", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      survey = insert(:survey, project: project)

      assert_error_sent :forbidden, fn ->
        get(conn, project_survey_links_path(conn, :create, project, survey, "results"))
      end

      assert_error_sent :forbidden, fn ->
        get(conn, project_survey_links_path(conn, :create, project, survey, "incentives"))
      end

      assert_error_sent :forbidden, fn ->
        get(conn, project_survey_links_path(conn, :create, project, survey, "interactions"))
      end

      assert_error_sent :forbidden, fn ->
        get(
          conn,
          project_survey_links_path(conn, :create, project, survey, "disposition_history")
        )
      end
    end

    test "forbids readers to refresh links", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      survey = insert(:survey, project: project)

      assert_error_sent :forbidden, fn ->
        put(conn, project_survey_links_path(conn, :refresh, project, survey, "results"))
      end

      assert_error_sent :forbidden, fn ->
        put(conn, project_survey_links_path(conn, :refresh, project, survey, "incentives"))
      end

      assert_error_sent :forbidden, fn ->
        put(conn, project_survey_links_path(conn, :refresh, project, survey, "interactions"))
      end

      assert_error_sent :forbidden, fn ->
        put(
          conn,
          project_survey_links_path(conn, :refresh, project, survey, "disposition_history")
        )
      end
    end

    test "forbids readers to delete links", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      survey = insert(:survey, project: project)

      assert_error_sent :forbidden, fn ->
        delete(conn, project_survey_links_path(conn, :delete, project, survey, "results"))
      end

      assert_error_sent :forbidden, fn ->
        delete(conn, project_survey_links_path(conn, :delete, project, survey, "incentives"))
      end

      assert_error_sent :forbidden, fn ->
        delete(conn, project_survey_links_path(conn, :delete, project, survey, "interactions"))
      end

      assert_error_sent :forbidden, fn ->
        delete(
          conn,
          project_survey_links_path(conn, :delete, project, survey, "disposition_history")
        )
      end
    end

    test "forbids to create links if project is archived", %{conn: conn, user: user} do
      project = create_project_for_user(user, archived: true)
      survey = insert(:survey, project: project)

      assert_error_sent :forbidden, fn ->
        get(conn, project_survey_links_path(conn, :create, project, survey, "results"))
      end

      assert_error_sent :forbidden, fn ->
        get(conn, project_survey_links_path(conn, :create, project, survey, "incentives"))
      end

      assert_error_sent :forbidden, fn ->
        get(conn, project_survey_links_path(conn, :create, project, survey, "interactions"))
      end

      assert_error_sent :forbidden, fn ->
        get(
          conn,
          project_survey_links_path(conn, :create, project, survey, "disposition_history")
        )
      end
    end

    test "forbids to refresh links if project is archived", %{conn: conn, user: user} do
      project = create_project_for_user(user, archived: true)
      survey = insert(:survey, project: project)

      assert_error_sent :forbidden, fn ->
        put(conn, project_survey_links_path(conn, :refresh, project, survey, "results"))
      end

      assert_error_sent :forbidden, fn ->
        put(conn, project_survey_links_path(conn, :refresh, project, survey, "incentives"))
      end

      assert_error_sent :forbidden, fn ->
        put(conn, project_survey_links_path(conn, :refresh, project, survey, "interactions"))
      end

      assert_error_sent :forbidden, fn ->
        put(
          conn,
          project_survey_links_path(conn, :refresh, project, survey, "disposition_history")
        )
      end
    end

    test "forbids to delete links if project is archived", %{conn: conn, user: user} do
      project = create_project_for_user(user, archived: true)
      survey = insert(:survey, project: project)

      assert_error_sent :forbidden, fn ->
        delete(conn, project_survey_links_path(conn, :delete, project, survey, "results"))
      end

      assert_error_sent :forbidden, fn ->
        delete(conn, project_survey_links_path(conn, :delete, project, survey, "incentives"))
      end

      assert_error_sent :forbidden, fn ->
        delete(conn, project_survey_links_path(conn, :delete, project, survey, "interactions"))
      end

      assert_error_sent :forbidden, fn ->
        delete(
          conn,
          project_survey_links_path(conn, :delete, project, survey, "disposition_history")
        )
      end
    end

    test "allows editors to create some links", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "editor")
      survey = insert(:survey, project: project)

      response = get(conn, project_survey_links_path(conn, :create, project, survey, "results"))
      assert response(response, 200)

      response =
        get(
          conn,
          project_survey_links_path(conn, :create, project, survey, "disposition_history")
        )

      assert response(response, 200)

      assert_error_sent :forbidden, fn ->
        get(conn, project_survey_links_path(conn, :create, project, survey, "incentives"))
      end

      assert_error_sent :forbidden, fn ->
        get(conn, project_survey_links_path(conn, :create, project, survey, "interactions"))
      end
    end

    test "allows editors to refresh some links", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "editor")
      survey = insert(:survey, project: project)
      get(conn, project_survey_links_path(conn, :create, project, survey, "results"))
      get(conn, project_survey_links_path(conn, :create, project, survey, "disposition_history"))

      response = put(conn, project_survey_links_path(conn, :refresh, project, survey, "results"))
      assert response(response, 200)

      response =
        put(
          conn,
          project_survey_links_path(conn, :refresh, project, survey, "disposition_history")
        )

      assert response(response, 200)

      assert_error_sent :forbidden, fn ->
        put(conn, project_survey_links_path(conn, :refresh, project, survey, "incentives"))
      end

      assert_error_sent :forbidden, fn ->
        put(conn, project_survey_links_path(conn, :refresh, project, survey, "interactions"))
      end
    end

    test "forbids editor to delete some links", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "editor")
      survey = insert(:survey, project: project)
      get(conn, project_survey_links_path(conn, :create, project, survey, "results"))
      get(conn, project_survey_links_path(conn, :create, project, survey, "disposition_history"))

      response =
        delete(conn, project_survey_links_path(conn, :delete, project, survey, "results"))

      assert response(response, 204)

      response =
        delete(
          conn,
          project_survey_links_path(conn, :delete, project, survey, "disposition_history")
        )

      assert response(response, 204)

      assert_error_sent :forbidden, fn ->
        delete(conn, project_survey_links_path(conn, :delete, project, survey, "incentives"))
      end

      assert_error_sent :forbidden, fn ->
        delete(conn, project_survey_links_path(conn, :delete, project, survey, "interactions"))
      end
    end
  end

  describe "activity logs" do
    setup %{conn: conn} do
      remote_ip = {192, 168, 0, 128}
      conn = %{conn | remote_ip: remote_ip}
      {:ok, conn: conn, remote_ip: remote_ip}
    end

    test "generates logs for results link", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      get(conn, project_survey_links_path(conn, :create, project, survey, "results"))

      activity_log_create =
        ActivityLog |> where([log], log.action == "enable_public_link") |> Repo.one()

      assert_link_log(%{
        log: activity_log_create,
        user: user,
        project: project,
        survey: survey,
        action: "enable_public_link",
        report_type: "survey_results",
        remote_ip: "192.168.0.128"
      })

      put(conn, project_survey_links_path(conn, :refresh, project, survey, "results"))

      activity_log_regenerate =
        ActivityLog |> where([log], log.action == "regenerate_public_link") |> Repo.one()

      assert_link_log(%{
        log: activity_log_regenerate,
        user: user,
        project: project,
        survey: survey,
        action: "regenerate_public_link",
        report_type: "survey_results",
        remote_ip: "192.168.0.128"
      })

      delete(conn, project_survey_links_path(conn, :delete, project, survey, "results"))

      activity_log_delete =
        ActivityLog |> where([log], log.action == "disable_public_link") |> Repo.one()

      assert_link_log(%{
        log: activity_log_delete,
        user: user,
        project: project,
        survey: survey,
        action: "disable_public_link",
        report_type: "survey_results",
        remote_ip: "192.168.0.128"
      })
    end

    test "generates logs for incentives link", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      get(conn, project_survey_links_path(conn, :create, project, survey, "incentives"))

      activity_log_create =
        ActivityLog |> where([log], log.action == "enable_public_link") |> Repo.one()

      assert_link_log(%{
        log: activity_log_create,
        user: user,
        project: project,
        survey: survey,
        action: "enable_public_link",
        report_type: "incentives",
        remote_ip: "192.168.0.128"
      })

      put(conn, project_survey_links_path(conn, :refresh, project, survey, "incentives"))

      activity_log_regenerate =
        ActivityLog |> where([log], log.action == "regenerate_public_link") |> Repo.one()

      assert_link_log(%{
        log: activity_log_regenerate,
        user: user,
        project: project,
        survey: survey,
        action: "regenerate_public_link",
        report_type: "incentives",
        remote_ip: "192.168.0.128"
      })

      delete(conn, project_survey_links_path(conn, :delete, project, survey, "incentives"))

      activity_log_delete =
        ActivityLog |> where([log], log.action == "disable_public_link") |> Repo.one()

      assert_link_log(%{
        log: activity_log_delete,
        user: user,
        project: project,
        survey: survey,
        action: "disable_public_link",
        report_type: "incentives",
        remote_ip: "192.168.0.128"
      })
    end

    test "generates logs for interactions link", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      get(conn, project_survey_links_path(conn, :create, project, survey, "interactions"))

      activity_log_create =
        ActivityLog |> where([log], log.action == "enable_public_link") |> Repo.one()

      assert_link_log(%{
        log: activity_log_create,
        user: user,
        project: project,
        survey: survey,
        action: "enable_public_link",
        report_type: "interactions",
        remote_ip: "192.168.0.128"
      })

      put(conn, project_survey_links_path(conn, :refresh, project, survey, "interactions"))

      activity_log_regenerate =
        ActivityLog |> where([log], log.action == "regenerate_public_link") |> Repo.one()

      assert_link_log(%{
        log: activity_log_regenerate,
        user: user,
        project: project,
        survey: survey,
        action: "regenerate_public_link",
        report_type: "interactions",
        remote_ip: "192.168.0.128"
      })

      delete(conn, project_survey_links_path(conn, :delete, project, survey, "interactions"))

      activity_log_delete =
        ActivityLog |> where([log], log.action == "disable_public_link") |> Repo.one()

      assert_link_log(%{
        log: activity_log_delete,
        user: user,
        project: project,
        survey: survey,
        action: "disable_public_link",
        report_type: "interactions",
        remote_ip: "192.168.0.128"
      })
    end

    test "generates logs for disposition_history link", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      get(conn, project_survey_links_path(conn, :create, project, survey, "disposition_history"))

      activity_log_create =
        ActivityLog |> where([log], log.action == "enable_public_link") |> Repo.one()

      assert_link_log(%{
        log: activity_log_create,
        user: user,
        project: project,
        survey: survey,
        action: "enable_public_link",
        report_type: "disposition_history",
        remote_ip: "192.168.0.128"
      })

      put(conn, project_survey_links_path(conn, :refresh, project, survey, "disposition_history"))

      activity_log_regenerate =
        ActivityLog |> where([log], log.action == "regenerate_public_link") |> Repo.one()

      assert_link_log(%{
        log: activity_log_regenerate,
        user: user,
        project: project,
        survey: survey,
        action: "regenerate_public_link",
        report_type: "disposition_history",
        remote_ip: "192.168.0.128"
      })

      delete(
        conn,
        project_survey_links_path(conn, :delete, project, survey, "disposition_history")
      )

      activity_log_delete =
        ActivityLog |> where([log], log.action == "disable_public_link") |> Repo.one()

      assert_link_log(%{
        log: activity_log_delete,
        user: user,
        project: project,
        survey: survey,
        action: "disable_public_link",
        report_type: "disposition_history",
        remote_ip: "192.168.0.128"
      })
    end
  end

  defp assert_log(log, user_id, project, survey, action, remote_ip) do
    assert log.project_id == project.id
    assert log.user_id == user_id
    assert log.entity_id == survey.id
    assert log.entity_type == "survey"
    assert log.action == action
    assert log.remote_ip == remote_ip
  end

  defp assert_link_log(%{
         log: log,
         user: user,
         project: project,
         survey: survey,
         action: action,
         report_type: report_type,
         remote_ip: remote_ip
       }) do
    assert_log(log, user.id, project, survey, action, remote_ip)

    assert log.metadata == %{
             "survey_name" => survey.name,
             "report_type" => report_type
           }
  end
end
