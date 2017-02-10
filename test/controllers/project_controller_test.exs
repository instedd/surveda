defmodule Ask.ProjectControllerTest do
  use Ask.ConnCase
  use Ask.DummySteps
  use Ask.TestHelpers

  alias Ask.Project
  @valid_attrs %{name: "some content"}

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")
    {:ok, conn: conn, user: user}
  end

  describe "index" do

    test "returns code 200 and empty list if there are no entries", %{conn: conn} do
      conn = get conn, project_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end

    test "list only entries of the current user on index", %{conn: conn, user: user} do
      user_project = create_project_for_user(user)
      insert(:project)

      project2 = insert(:project)
      insert(:project_membership, user_id: user.id, project_id: project2.id, level: "reader")

      conn = get conn, project_path(conn, :index)
      assert json_response(conn, 200)["data"] == [
        %{
          "id"      => user_project.id,
          "name"    => user_project.name,
          "running_surveys" => 0,
          "updated_at" => Ecto.DateTime.to_iso8601(user_project.updated_at),
          "read_only" => false,
        },
        %{
          "id"      => project2.id,
          "name"    => project2.name,
          "running_surveys" => 0,
          "updated_at" => Ecto.DateTime.to_iso8601(project2.updated_at),
          "read_only" => true,
        }
      ]
    end

    test "shows running survey count", %{conn: conn, user: user} do
      project1 = create_project_for_user(user)
      insert(:survey, project: project1, state: "running")
      insert(:survey, project: project1, state: "running")
      insert(:survey, project: project1, state: "pending")

      project2 = create_project_for_user(user)
      insert(:survey, project: project2, state: "running")
      insert(:survey, project: project2, state: "pending")

      project3 = create_project_for_user(user)

      conn = get conn, project_path(conn, :index)
      project_map_1 = %{"id"      => project1.id,
                          "name"    => project1.name,
                          "running_surveys" => 2,
                          "updated_at" => Ecto.DateTime.to_iso8601(project1.updated_at),
                          "read_only" => false}
      project_map_2 = %{"id"      => project2.id,
                          "name"    => project2.name,
                          "running_surveys" => 1,
                          "updated_at" => Ecto.DateTime.to_iso8601(project2.updated_at),
                          "read_only" => false}
      project_map_3 = %{"id"      => project3.id,
                          "name"    => project3.name,
                          "running_surveys" => 0,
                          "updated_at" => Ecto.DateTime.to_iso8601(project3.updated_at),
                          "read_only" => false}
      assert json_response(conn, 200)["data"] == [project_map_1, project_map_2, project_map_3]
    end

  end

  describe "show" do

    test "shows chosen resource", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      conn = get conn, project_path(conn, :show, project)
      assert json_response(conn, 200)["data"] == %{"id" => project.id,
        "name" => project.name,
        "updated_at" => Ecto.DateTime.to_iso8601(project.updated_at),
        "read_only" => false}
    end

    test "shows chosen resource as read_only", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      conn = get conn, project_path(conn, :show, project)
      assert json_response(conn, 200)["data"] == %{"id" => project.id,
        "name" => project.name,
        "updated_at" => Ecto.DateTime.to_iso8601(project.updated_at),
        "read_only" => true}
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, project_path(conn, :show, -1)
      end
    end

    test "forbid access to projects from other users", %{conn: conn} do
      project = insert(:project)
      assert_error_sent :forbidden, fn ->
        get conn, project_path(conn, :show, project)
      end
    end

    test "shows chosen resource as project reader", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      conn = get conn, project_path(conn, :show, project)
      assert json_response(conn, 200)["data"] == %{"id" => project.id,
        "name" => project.name,
        "updated_at" => Ecto.DateTime.to_iso8601(project.updated_at),
        "read_only" => true}
    end

  end

  describe "create" do

    test "creates and renders resource when data is valid", %{conn: conn} do
      conn = post conn, project_path(conn, :create), project: @valid_attrs
      response = json_response(conn, 201)
      assert response["data"]["id"]
      assert response["data"]["read_only"] == false
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
      assert Repo.get_by(Project, @valid_attrs)
    end

    test "rejects update if the project doesn't belong to the current user", %{conn: conn} do
      project = insert(:project)
      assert_error_sent :forbidden, fn ->
        put conn, project_path(conn, :update, project), project: @valid_attrs
      end
    end

    test "rejects update if the project belong to the current user but as reader", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      assert_error_sent :forbidden, fn ->
        put conn, project_path(conn, :update, project), project: @valid_attrs
      end
    end

  end

  describe "delete" do

    test "deletes chosen resource", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      conn = delete conn, project_path(conn, :delete, project)
      assert response(conn, 204)
      refute Repo.get(Project, project.id)
    end

    test "rejects delete if the project doesn't belong to the current user", %{conn: conn} do
      project = insert(:project)
      assert_error_sent :forbidden, fn ->
        delete conn, project_path(conn, :delete, project)
      end
    end

    test "rejects delete if the project belongs to the current user as reader", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      assert_error_sent :forbidden, fn ->
        delete conn, project_path(conn, :delete, project)
      end
    end

  end

  test "autocomplete vars", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    q1 = insert(:questionnaire, project: project, steps: @dummy_steps)
    q1 |> Ask.Questionnaire.recreate_variables!

    conn = get conn, project_autocomplete_vars_path(conn, :autocomplete_vars, project.id, %{"text" => "E"})
    assert json_response(conn, 200) == ["Exercises"]
  end

  test "autocomplete primary language", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    q1 = insert(:questionnaire, project: project, steps: @dummy_steps)
    q1 |> Ask.Translation.rebuild

    conn = get conn, project_autocomplete_primary_language_path(conn, :autocomplete_primary_language, project.id,
             %{"mode" => "sms", "language" => "en", "text" => "you"})
    assert json_response(conn, 200) == [
      %{"text" => "Do you exercise? Reply 1 for YES, 2 for NO",
        "translations" => [%{"language" => "es",
           "text" => "Do you exercise? Reply 1 for YES, 2 for NO (Spanish)"}]},
      %{"text" => "Do you smoke? Reply 1 for YES, 2 for NO",
        "translations" => [%{"language" => "es",
           "text" => "Do you smoke? Reply 1 for YES, 2 for NO (Spanish)"}]},
      %{"text" => "You have entered an invalid answer",
        "translations" => [%{"language" => nil, "text" => nil}]}
    ]
  end

  test "autocomplete other language", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    q1 = insert(:questionnaire, project: project, steps: @dummy_steps)
    q1 |> Ask.Translation.rebuild

    conn = get conn, project_autocomplete_other_language_path(conn, :autocomplete_other_language, project.id,
             %{"mode" => "sms", "primary_language" => "en", "other_language" => "es",
               "source_text" => "Do you exercise? Reply 1 for YES, 2 for NO",
               "target_text" => "Do you exercise? Reply 1 for YES, 2 for NO (S"})
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
    conn = get conn, project_collaborators_path(conn, :collaborators, project.id)

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
    conn = get conn, project_collaborators_path(conn, :collaborators, project.id)

    assert json_response(conn, 200)["data"]["collaborators"] == [
      %{"email" => user.email, "role" => "owner", "invited" => false, "code" => nil},
      %{"email" => user2.email, "role" => "editor", "invited" => true, "code" => code}
    ]
  end

end
