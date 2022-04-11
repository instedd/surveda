defmodule AskWeb.ProjectControllerTest do
  use AskWeb.ConnCase
  use Ask.DummySteps
  use Ask.TestHelpers

  alias Ask.{Project, ActivityLog}
  @valid_attrs %{name: "some content"}

  setup %{conn: conn} do
    user = insert(:user)

    conn =
      conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn, user: user}
  end

  defp cast!(str) do
    case DateTime.from_iso8601(str) do
      {:ok, datetime, _} -> datetime
      {:error, error} -> {:error, error}
    end
  end

  describe "index" do
    test "returns code 200 and empty list if there are no entries", %{conn: conn} do
      conn = get(conn, project_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end

    test "list only entries of the current user on index", %{conn: conn, user: user} do
      user_project = create_project_for_user(user)
      user_project = Project |> Repo.get(user_project.id)
      insert(:project)

      project2 = insert(:project)
      project2 = Project |> Repo.get(project2.id)
      insert(:project_membership, user_id: user.id, project_id: project2.id, level: "reader")

      conn = get(conn, project_path(conn, :index))

      assert json_response(conn, 200)["data"] == [
               %{
                 "id" => user_project.id,
                 "name" => user_project.name,
                 "running_surveys" => 0,
                 "updated_at" => to_iso8601(user_project.updated_at),
                 "read_only" => false,
                 "colour_scheme" => "default",
                 "owner" => true,
                 "level" => "owner"
               },
               %{
                 "id" => project2.id,
                 "name" => project2.name,
                 "running_surveys" => 0,
                 "updated_at" => to_iso8601(project2.updated_at),
                 "read_only" => true,
                 "colour_scheme" => "default",
                 "owner" => false,
                 "level" => "reader"
               }
             ]
    end

    test "returns archived projects only", %{conn: conn, user: user} do
      archived_project = create_project_for_user(user, archived: true)
      create_project_for_user(user, archived: false)
      archived_project = Project |> Repo.get(archived_project.id)

      conn = get(conn, project_path(conn, :index, %{"archived" => "true"}))

      assert json_response(conn, 200)["data"] == [
               %{
                 "id" => archived_project.id,
                 "name" => archived_project.name,
                 "running_surveys" => 0,
                 "updated_at" => to_iso8601(archived_project.updated_at),
                 "read_only" => true,
                 "colour_scheme" => "default",
                 "owner" => true,
                 "level" => "owner"
               }
             ]
    end

    test "returns non archived projects only", %{conn: conn, user: user} do
      create_project_for_user(user, archived: true)
      active_project = create_project_for_user(user, archived: false) |> Repo.reload()

      conn = get(conn, project_path(conn, :index, %{"archived" => "false"}))

      assert json_response(conn, 200)["data"] == [
               %{
                 "id" => active_project.id,
                 "name" => active_project.name,
                 "running_surveys" => 0,
                 "updated_at" => to_iso8601(active_project.updated_at),
                 "read_only" => false,
                 "colour_scheme" => "default",
                 "owner" => true,
                 "level" => "owner"
               }
             ]
    end

    test "returns all projects when no parameter is send", %{conn: conn, user: user} do
      archived_project = create_project_for_user(user, archived: true) |> Repo.reload()
      active_project = create_project_for_user(user, archived: false) |> Repo.reload()

      conn = get(conn, project_path(conn, :index))

      assert json_response(conn, 200)["data"] == [
               %{
                 "id" => archived_project.id,
                 "name" => archived_project.name,
                 "running_surveys" => 0,
                 "updated_at" => to_iso8601(archived_project.updated_at),
                 "read_only" => true,
                 "colour_scheme" => "default",
                 "owner" => true,
                 "level" => "owner"
               },
               %{
                 "id" => active_project.id,
                 "name" => active_project.name,
                 "running_surveys" => 0,
                 "updated_at" => to_iso8601(active_project.updated_at),
                 "read_only" => false,
                 "colour_scheme" => "default",
                 "owner" => true,
                 "level" => "owner"
               }
             ]
    end

    test "shows running survey count", %{conn: conn, user: user} do
      project1 = create_project_for_user(user)
      project1 = Project |> Repo.get(project1.id)
      insert(:survey, project: project1, state: "running")
      insert(:survey, project: project1, state: "running")
      insert(:survey, project: project1, state: "pending")

      project2 = create_project_for_user(user)
      project2 = Project |> Repo.get(project2.id)
      insert(:survey, project: project2, state: "running")
      insert(:survey, project: project2, state: "pending")

      project3 = create_project_for_user(user)
      project3 = Project |> Repo.get(project3.id)

      conn = get(conn, project_path(conn, :index))

      project_map_1 = %{
        "id" => project1.id,
        "name" => project1.name,
        "running_surveys" => 2,
        "updated_at" => to_iso8601(project1.updated_at),
        "read_only" => false,
        "colour_scheme" => "default",
        "owner" => true,
        "level" => "owner"
      }

      project_map_2 = %{
        "id" => project2.id,
        "name" => project2.name,
        "running_surveys" => 1,
        "updated_at" => to_iso8601(project2.updated_at),
        "read_only" => false,
        "colour_scheme" => "default",
        "owner" => true,
        "level" => "owner"
      }

      project_map_3 = %{
        "id" => project3.id,
        "name" => project3.name,
        "running_surveys" => 0,
        "updated_at" => to_iso8601(project3.updated_at),
        "read_only" => false,
        "colour_scheme" => "default",
        "owner" => true,
        "level" => "owner"
      }

      assert json_response(conn, 200)["data"] == [project_map_1, project_map_2, project_map_3]
    end
  end

  describe "show" do
    test "shows chosen resource", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      project = Project |> Repo.get(project.id)
      conn = get(conn, project_path(conn, :show, project))

      assert json_response(conn, 200)["data"] == %{
               "id" => project.id,
               "name" => project.name,
               "updated_at" => to_iso8601(project.updated_at),
               "read_only" => false,
               "colour_scheme" => "default",
               "owner" => true,
               "level" => "owner"
             }
    end

    test "shows chosen resource as read_only", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      project = Project |> Repo.get(project.id)
      conn = get(conn, project_path(conn, :show, project))

      assert json_response(conn, 200)["data"] == %{
               "id" => project.id,
               "name" => project.name,
               "updated_at" => to_iso8601(project.updated_at),
               "read_only" => true,
               "colour_scheme" => "default",
               "owner" => false,
               "level" => "reader"
             }
    end

    test "read_only is true when project is archived", %{conn: conn, user: user} do
      project = create_project_for_user(user, archived: true)
      conn = get(conn, project_path(conn, :show, project))
      assert json_response(conn, 200)["data"]["read_only"]
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent 404, fn ->
        get(conn, project_path(conn, :show, -1))
      end
    end

    test "forbid access to projects from other users", %{conn: conn} do
      project = insert(:project)

      assert_error_sent :forbidden, fn ->
        get(conn, project_path(conn, :show, project))
      end
    end

    test "shows chosen resource as project reader", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      project = Project |> Repo.get(project.id)
      conn = get(conn, project_path(conn, :show, project))

      assert json_response(conn, 200)["data"] == %{
               "id" => project.id,
               "name" => project.name,
               "updated_at" => to_iso8601(project.updated_at),
               "read_only" => true,
               "colour_scheme" => "default",
               "owner" => false,
               "level" => "reader"
             }
    end
  end

  describe "create" do
    test "creates and renders resource when data is valid", %{conn: conn} do
      conn = post conn, project_path(conn, :create), project: @valid_attrs
      response = json_response(conn, 201)
      assert response["data"]["id"]
      assert response["data"]["read_only"] == false
      assert response["data"]["owner"] == true
      assert Repo.get_by(Project, @valid_attrs)
    end
  end

  describe "update" do
    test "updates and renders chosen resource when data is valid", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      conn = put conn, project_path(conn, :update, project), project: @valid_attrs
      response = json_response(conn, 200)
      assert response["data"]["id"]
      assert response["data"]["read_only"] == false
      assert response["data"]["owner"] == true
      assert Repo.get_by(Project, @valid_attrs)
    end

    test "sets archived status to true", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      put conn, project_update_archived_status_path(conn, :update_archived_status, project),
        project: %{"archived" => true}

      project = Project |> Repo.get(project.id)
      assert project.archived
    end

    test "sets archived status to false", %{conn: conn, user: user} do
      project = create_project_for_user(user, archived: true)

      put conn, project_update_archived_status_path(conn, :update_archived_status, project),
        project: %{"archived" => false}

      project = Project |> Repo.get(project.id)
      assert project.archived == false
    end

    test "rejects archived parameter when it is invalid", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      conn =
        put conn, project_update_archived_status_path(conn, :update_archived_status, project),
          project: %{"archived" => "foo"}

      assert json_response(conn, 422)["errors"]["archived"] == ["is invalid"]
    end

    test "rejects archived parameter when it is empty", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      conn =
        put conn, project_update_archived_status_path(conn, :update_archived_status, project),
          project: %{"archived" => ""}

      assert json_response(conn, 422)["errors"]["archived"] == ["is invalid"]
    end

    test "rejects archived status update if user level is reader or editor", %{
      conn: conn,
      user: user
    } do
      ["reader", "editor"]
      |> Enum.each(fn level ->
        project = create_project_for_user(user, level: level)

        assert_error_sent :forbidden, fn ->
          put conn, project_update_archived_status_path(conn, :update_archived_status, project),
            project: %{"archived" => "true"}
        end
      end)
    end

    test "updates colour_scheme when it is valid", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      conn =
        put conn, project_path(conn, :update, project),
          project: %{colour_scheme: "better_data_for_health"}

      response = json_response(conn, 200)
      assert response["data"]["id"]
      assert response["data"]["colour_scheme"] == "better_data_for_health"
    end

    test "rejects update when colour_scheme is invalid", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      conn =
        put conn, project_path(conn, :update, project),
          project: %{colour_scheme: "invalid scheme"}

      assert json_response(conn, 422)["errors"]["colour_scheme"] == [
               "value has to be either default or better_data_for_health"
             ]
    end

    test "rejects update if the project doesn't belong to the current user", %{conn: conn} do
      project = insert(:project)

      assert_error_sent :forbidden, fn ->
        put conn, project_path(conn, :update, project), project: @valid_attrs
      end
    end

    test "rejects update if the project belong to the current user but as reader", %{
      conn: conn,
      user: user
    } do
      project = create_project_for_user(user, level: "reader")

      assert_error_sent :forbidden, fn ->
        put conn, project_path(conn, :update, project), project: @valid_attrs
      end
    end

    test "rejects update if project is archived", %{conn: conn, user: user} do
      project = create_project_for_user(user, archived: true)

      assert_error_sent :forbidden, fn ->
        put conn, project_path(conn, :update, project), project: @valid_attrs
      end
    end
  end

  describe "delete" do
    test "deletes chosen resource", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      conn = delete(conn, project_path(conn, :delete, project))
      assert response(conn, 204)
      refute Repo.get(Project, project.id)
    end

    test "rejects delete if the project doesn't belong to the current user", %{conn: conn} do
      project = insert(:project)

      assert_error_sent :forbidden, fn ->
        delete(conn, project_path(conn, :delete, project))
      end
    end

    test "rejects delete if the project belongs to the current user as reader", %{
      conn: conn,
      user: user
    } do
      project = create_project_for_user(user, level: "reader")

      assert_error_sent :forbidden, fn ->
        delete(conn, project_path(conn, :delete, project))
      end
    end
  end

  test "autocomplete vars", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    q1 = insert(:questionnaire, project: project, steps: @dummy_steps)
    q1 |> Ask.Questionnaire.recreate_variables!()

    conn =
      get(
        conn,
        project_autocomplete_vars_path(conn, :autocomplete_vars, project.id, %{"text" => "E"})
      )

    assert json_response(conn, 200) == ["Exercises"]
  end

  test "autocomplete primary language", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    q1 = insert(:questionnaire, project: project, steps: @dummy_steps)
    q1 |> Ask.Translation.rebuild()

    conn =
      get(
        conn,
        project_autocomplete_primary_language_path(
          conn,
          :autocomplete_primary_language,
          project.id,
          %{"mode" => "sms", "scope" => "prompt", "language" => "en", "text" => "you"}
        )
      )

    assert json_response(conn, 200) == [
             %{
               "text" => "Do you exercise? Reply 1 for YES, 2 for NO",
               "translations" => [
                 %{
                   "language" => "es",
                   "text" => "Do you exercise? Reply 1 for YES, 2 for NO (Spanish)"
                 }
               ]
             },
             %{
               "text" => "Do you smoke? Reply 1 for YES, 2 for NO",
               "translations" => [
                 %{
                   "language" => "es",
                   "text" => "Do you smoke? Reply 1 for YES, 2 for NO (Spanish)"
                 }
               ]
             }
           ]
  end

  test "autocomplete other language", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    q1 = insert(:questionnaire, project: project, steps: @dummy_steps)
    q1 |> Ask.Translation.rebuild()

    conn =
      get(
        conn,
        project_autocomplete_other_language_path(
          conn,
          :autocomplete_other_language,
          project.id,
          %{
            "mode" => "sms",
            "scope" => "prompt",
            "primary_language" => "en",
            "other_language" => "es",
            "source_text" => "Do you exercise? Reply 1 for YES, 2 for NO",
            "target_text" => "Do you exercise? Reply 1 for YES, 2 for NO (S"
          }
        )
      )

    assert json_response(conn, 200) == [
             "Do you exercise? Reply 1 for YES, 2 for NO (Spanish)"
           ]
  end

  test "lists collaborators", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    user2 = insert(:user)
    user3 = insert(:user)
    insert(:project_membership, user_id: user2.id, project_id: project.id, level: "editor")
    insert(:project_membership, user_id: user3.id, project_id: project.id, level: "reader")
    conn = get(conn, project_collaborators_path(conn, :collaborators, project.id))

    assert json_response(conn, 200)["data"]["collaborators"] == [
             %{"email" => user.email, "role" => "owner", "invited" => false, "code" => nil},
             %{"email" => user2.email, "role" => "editor", "invited" => false, "code" => nil},
             %{"email" => user3.email, "role" => "reader", "invited" => false, "code" => nil}
           ]
  end

  test "collaborators include invited members", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    user2 = insert(:user)
    code = "aw3ey233ser"
    insert(:invite, email: user2.email, project_id: project.id, level: "editor", code: code)
    conn = get(conn, project_collaborators_path(conn, :collaborators, project.id))

    assert json_response(conn, 200)["data"]["collaborators"] == [
             %{"email" => user.email, "role" => "owner", "invited" => false, "code" => nil},
             %{"email" => user2.email, "role" => "editor", "invited" => true, "code" => code}
           ]
  end

  describe "activity logs" do
    test "lists activities", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      collaborator_email = "foo@foo.com"

      %{id: create_invite_id} =
        insert(:activity_log,
          project: project,
          user: user,
          entity_type: "project",
          entity_id: project.id,
          action: "create_invite",
          inserted_at: cast!("2000-01-01T00:00:00Z"),
          metadata: %{
            project_name: project.name,
            collaborator_email: collaborator_email,
            role: "editor"
          }
        )

      %{id: enable_link_id} =
        insert(:activity_log,
          project: project,
          action: "enable_public_link",
          inserted_at: cast!("2000-01-02T00:00:00Z"),
          user: user,
          entity_type: "survey",
          entity_id: survey.id,
          metadata: %{survey_name: survey.name, report_type: "survey_results"}
        )

      create_invite_log = ActivityLog |> Repo.get!(create_invite_id)
      enable_link_log = ActivityLog |> Repo.get!(enable_link_id)

      conn = get(conn, project_activities_path(conn, :activities, project.id))

      assert json_response(conn, 200)["data"]["activities"] == [
               %{
                 "user_name" => user.name,
                 "user_email" => user.email,
                 "action" => "create_invite",
                 "entity_type" => "project",
                 "id" => create_invite_id,
                 "inserted_at" => to_iso8601(create_invite_log.inserted_at),
                 "remote_ip" => "192.168.0.1",
                 "metadata" => %{
                   "project_name" => project.name,
                   "collaborator_email" => collaborator_email,
                   "role" => "editor"
                 }
               },
               %{
                 "user_name" => user.name,
                 "user_email" => user.email,
                 "action" => "enable_public_link",
                 "entity_type" => "survey",
                 "id" => enable_link_id,
                 "remote_ip" => "192.168.0.1",
                 "inserted_at" => to_iso8601(enable_link_log.inserted_at),
                 "metadata" => %{
                   "survey_name" => survey.name,
                   "report_type" => "survey_results"
                 }
               }
             ]

      assert json_response(conn, 200)["meta"]["count"] == 2
    end

    test "paginates activities", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      insert(:activity_log,
        project: project,
        action: "create_invite",
        inserted_at: cast!("2000-01-01T00:00:00Z")
      )

      insert(:activity_log,
        project: project,
        action: "edit_collaborator",
        inserted_at: cast!("2000-01-02T00:00:00Z")
      )

      insert(:activity_log,
        project: project,
        action: "enable_public_link",
        inserted_at: cast!("2000-01-03T00:00:00Z")
      )

      insert(:activity_log,
        project: project,
        action: "start",
        inserted_at: cast!("2000-01-04T00:00:00Z")
      )

      first_page =
        get(conn, project_activities_path(conn, :activities, project.id, page: 1, limit: 2))

      second_page =
        get(conn, project_activities_path(conn, :activities, project.id, page: 2, limit: 2))

      assert json_response(first_page, 200)["data"]["activities"] |> Enum.map(& &1["action"]) == [
               "create_invite",
               "edit_collaborator"
             ]

      assert json_response(first_page, 200)["meta"]["count"] == 4

      assert json_response(second_page, 200)["data"]["activities"] |> Enum.map(& &1["action"]) ==
               ["enable_public_link", "start"]

      assert json_response(second_page, 200)["meta"]["count"] == 4
    end

    test "sort activities by insertedAt in ascendent order", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      insert(:activity_log,
        project: project,
        action: "create_invite",
        inserted_at: cast!("2000-01-01T00:00:00Z")
      )

      insert(:activity_log,
        project: project,
        action: "edit_collaborator",
        inserted_at: cast!("2000-01-02T00:00:00Z")
      )

      insert(:activity_log,
        project: project,
        action: "enable_public_link",
        inserted_at: cast!("2000-01-03T00:00:00Z")
      )

      insert(:activity_log,
        project: project,
        action: "start",
        inserted_at: cast!("2000-01-04T00:00:00Z")
      )

      first_page =
        get(
          conn,
          project_activities_path(conn, :activities, project.id,
            page: 1,
            limit: 2,
            sort_by: "insertedAt",
            sort_asc: true
          )
        )

      second_page =
        get(
          conn,
          project_activities_path(conn, :activities, project.id,
            page: 2,
            limit: 2,
            sort: "insertedAt",
            sort_asc: true
          )
        )

      assert json_response(first_page, 200)["data"]["activities"] |> Enum.map(& &1["action"]) == [
               "create_invite",
               "edit_collaborator"
             ]

      assert json_response(first_page, 200)["meta"]["count"] == 4

      assert json_response(second_page, 200)["data"]["activities"] |> Enum.map(& &1["action"]) ==
               ["enable_public_link", "start"]

      assert json_response(second_page, 200)["meta"]["count"] == 4
    end

    test "sort activities by insertedAt in descendent order", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      insert(:activity_log,
        project: project,
        action: "create_invite",
        inserted_at: cast!("2000-01-01T00:00:00Z")
      )

      insert(:activity_log,
        project: project,
        action: "edit_collaborator",
        inserted_at: cast!("2000-01-02T00:00:00Z")
      )

      insert(:activity_log,
        project: project,
        action: "enable_public_link",
        inserted_at: cast!("2000-01-03T00:00:00Z")
      )

      insert(:activity_log,
        project: project,
        action: "start",
        inserted_at: cast!("2000-01-04T00:00:00Z")
      )

      first_page =
        get(
          conn,
          project_activities_path(conn, :activities, project.id,
            page: 1,
            limit: 2,
            sort_by: "insertedAt",
            sort_asc: false
          )
        )

      second_page =
        get(
          conn,
          project_activities_path(conn, :activities, project.id,
            page: 2,
            limit: 2,
            sort_by: "insertedAt",
            sort_asc: false
          )
        )

      assert json_response(first_page, 200)["data"]["activities"] |> Enum.map(& &1["action"]) == [
               "start",
               "enable_public_link"
             ]

      assert json_response(first_page, 200)["meta"]["count"] == 4

      assert json_response(second_page, 200)["data"]["activities"] |> Enum.map(& &1["action"]) ==
               ["edit_collaborator", "create_invite"]

      assert json_response(second_page, 200)["meta"]["count"] == 4
    end

    test "doesn't list activities of other project", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      project2 = create_project_for_user(user)
      survey = insert(:survey, project: project)
      collaborator_email = "foo@foo.com"

      %{id: create_invite_id} =
        insert(:activity_log,
          project: project,
          user: user,
          entity_type: "project",
          entity_id: project.id,
          action: "create_invite",
          inserted_at: cast!("2000-01-01T00:00:00Z"),
          metadata: %{
            project_name: project.name,
            collaborator_email: collaborator_email,
            role: "editor"
          }
        )

      insert(:activity_log,
        project: project2,
        action: "enable_public_link",
        inserted_at: cast!("2000-01-02T00:00:00Z"),
        user: user,
        entity_type: "survey",
        entity_id: survey.id,
        metadata: %{survey_name: survey.name, report_type: "survey_results"}
      )

      create_invite_log = ActivityLog |> Repo.get!(create_invite_id)

      conn = get(conn, project_activities_path(conn, :activities, project.id))

      assert json_response(conn, 200)["data"]["activities"] == [
               %{
                 "user_name" => user.name,
                 "user_email" => user.email,
                 "action" => "create_invite",
                 "entity_type" => "project",
                 "id" => create_invite_log.id,
                 "remote_ip" => "192.168.0.1",
                 "inserted_at" => to_iso8601(create_invite_log.inserted_at),
                 "metadata" => %{
                   "project_name" => project.name,
                   "collaborator_email" => collaborator_email,
                   "role" => "editor"
                 }
               }
             ]
    end

    test "forbid access if user is not member of the project", %{conn: conn} do
      project = insert(:project)

      assert_error_sent :forbidden, fn ->
        get(conn, project_activities_path(conn, :activities, project))
      end
    end
  end
end
