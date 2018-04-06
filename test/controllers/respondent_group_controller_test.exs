defmodule Ask.RespondentGroupControllerTest do
  use Ask.ConnCase
  use Ask.TestHelpers

  alias Ask.{Project, RespondentGroup, Respondent, Channel, RespondentGroupChannel, Stats}

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "returns code 200 and empty list if there are no entries", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      conn = get conn, project_survey_respondent_group_path(conn, :index, project.id, survey.id)
      assert json_response(conn, 200)["data"] == []
    end

    test "renders one group", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      group = insert(:respondent_group, survey: survey, sample: ["12345", "23456"], respondents_count: 3)
      channel = insert(:channel, name: "test")
      add_channel_to(group, channel)

      sample = group.sample |> Enum.map(&Respondent.mask_phone_number/1)

      conn = get conn, project_survey_respondent_group_path(conn, :index, project.id, survey.id)
      assert json_response(conn, 200)["data"] == [%{
        "id" => group.id,
        "name" => group.name,
        "sample" => sample,
        "respondents_count" => group.respondents_count,
        "channels" => [%{"id" => channel.id, "mode" => channel.type}],
      }]
    end
  end

  describe "create" do
    test "uploads CSV file with phone numbers and creates and renders resource when data is valid", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers.csv", filename: "phone_numbers.csv"}

      conn = post conn, project_survey_respondent_group_path(conn, :create, project.id, survey.id), file: file
      group = RespondentGroup |> Repo.get_by(survey_id: survey.id)

      sample = group.sample |> Enum.map(&Respondent.mask_phone_number/1)

      assert json_response(conn, 201)["data"] == %{
        "id" => group.id,
        "name" => group.name,
        "sample" => sample,
        "respondents_count" => group.respondents_count,
        "channels" => [],
      }

      respondents = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)

      assert length(respondents) == 14

      assert hd(respondents).disposition == "registered"

      assert group
      assert group.name == "phone_numbers.csv"
      assert group.respondents_count == 14
      assert group.sample == respondents |> Enum.take(5) |> Enum.map(&(&1.phone_number))

      assert Enum.at(respondents, 0).survey_id == survey.id
      assert Enum.at(respondents, 0).phone_number == "(549) 11 4234 2343"
      assert Enum.at(respondents, 0).sanitized_phone_number == "5491142342343"
      assert Enum.at(respondents, 0).respondent_group_id == group.id
      assert Enum.at(respondents, 0).stats == %Stats{}
    end

    test "does not upload a CSV file for a new group when the survey is running", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: "running")

      file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers.csv", filename: "phone_numbers.csv"}

      conn = post conn, project_survey_respondent_group_path(conn, :create, project.id, survey.id), file: file
      assert json_response(conn, 422)

      all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
      assert length(all) == 0
    end

    test "uploads CSV file with phone numbers ignoring additional columns", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers_additional_columns.csv", filename: "phone_numbers.csv"}

      conn = post conn, project_survey_respondent_group_path(conn, :create, project.id, survey.id), file: file
      assert json_response(conn, 201)

      all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
      assert length(all) == 14
      assert Enum.at(all, 0).survey_id == survey.id
      assert Enum.at(all, 0).phone_number == "(549) 11 4234 2343"
    end

    test "uploads CSV file with single line", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers_one.csv", filename: "phone_numbers.csv"}

      conn = post conn, project_survey_respondent_group_path(conn, :create, project.id, survey.id), file: file
      assert json_response(conn, 201)

      all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
      assert length(all) == 1
      assert Enum.at(all, 0).survey_id == survey.id
      assert Enum.at(all, 0).phone_number == "123456789"
    end

    test "uploads CSV file with phone and creates and renders resource when data contains special characters but is valid", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers_special_characters.csv", filename: "phone_numbers.csv"}

      conn = post conn, project_survey_respondent_group_path(conn, :create, project.id, survey.id), file: file
      assert conn.status == 201
      all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
      assert length(all) == 3
      assert Enum.at(all, 0).phone_number == "+154 11 1213 2345"
    end

    test "uploads CSV file with phone numbers but does not create and render resource when numbers contains invalid characters", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers_invalid.csv", filename: "phone_numbers.csv"}

      conn = post conn, project_survey_respondent_group_path(conn, :create, project.id, survey.id), file: file
      assert conn.status == 422
      all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
      assert length(all) == 0
    end

    test "uploads empty CSV file", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers_empty.csv", filename: "phone_numbers.csv"}

      conn = post conn, project_survey_respondent_group_path(conn, :create, project.id, survey.id), file: file
      assert conn.status == 422
      all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
      assert length(all) == 0
    end

    test "uploads CSV file with phone numbers rejecting duplicated entries", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers_duplicated.csv", filename: "phone_numbers.csv"}

      conn = post conn, project_survey_respondent_group_path(conn, :create, project.id, survey.id), file: file
      assert json_response(conn, 201)["data"]["respondents_count"] == 16

      all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
      assert length(all) == 16
      assert Enum.at(all, 0).survey_id == survey.id
      assert Enum.at(all, 0).phone_number == "(549) 11 4234 2343"
    end

    test "uploads CSV file with phone numbers rejecting duplicated entries (consider space, symbols, etc.)", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers_duplicated2.csv", filename: "phone_numbers.csv"}

      conn = post conn, project_survey_respondent_group_path(conn, :create, project.id, survey.id), file: file
      assert json_response(conn, 201)["data"]["respondents_count"] == 1

      all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
      assert length(all) == 1
      assert Enum.at(all, 0).survey_id == survey.id
      assert Enum.at(all, 0).phone_number == "+1234567"
    end

    test "it supports \r as a field separator", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers_r.csv", filename: "phone_numbers.csv"}

      conn = post conn, project_survey_respondent_group_path(conn, :create, project.id, survey.id), file: file
      assert json_response(conn, 201)["data"]["respondents_count"] == 4

      all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
      assert length(all) == 4
      assert Enum.at(all, 0).survey_id == survey.id
      assert Enum.at(all, 0).phone_number == "15044020205"
    end

    test "it supports \n as a field separator", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers_newline.csv", filename: "phone_numbers.csv"}

      conn = post conn, project_survey_respondent_group_path(conn, :create, project.id, survey.id), file: file
      assert json_response(conn, 201)["data"]["respondents_count"] == 4

      all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
      assert length(all) == 4
      assert Enum.at(all, 0).survey_id == survey.id
      assert Enum.at(all, 0).phone_number == "15044020205"
    end

    test "upload CSV file with UTF-16 LE encoding (with BOM)", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers_utf16le.csv", filename: "phone_numbers.csv"}

      conn = post conn, project_survey_respondent_group_path(conn, :create, project.id, survey.id), file: file
      assert json_response(conn, 201)["data"]["respondents_count"] == 4

      all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
      assert length(all) == 4
      assert Enum.at(all, 0).survey_id == survey.id
      assert Enum.at(all, 0).phone_number == "15044020205"
    end

    test "updates project updated_at when uploading CSV", %{conn: conn, user: user}  do
      {:ok, datetime, _} = DateTime.from_iso8601("2000-01-01T00:00:00Z")
      project = create_project_for_user(user, updated_at: datetime)
      survey = insert(:survey, project: project)

      file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers.csv", filename: "phone_numbers.csv"}
      post conn, project_survey_respondent_group_path(conn, :create, project.id, survey.id), file: file

      project = Project |> Repo.get(project.id)
      assert DateTime.compare(project.updated_at, datetime) == :gt
    end

    test "forbids upload for project reader", %{conn: conn, user: user}  do
      datetime = Ecto.DateTime.cast!("2000-01-01 00:00:00")
      project = insert(:project, updated_at: datetime)
      insert(:project_membership, user: user, project: project, level: "reader")
      survey = insert(:survey, project: project)

      file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers.csv", filename: "phone_numbers.csv"}
      assert_error_sent :forbidden, fn ->
        post conn, project_survey_respondent_group_path(conn, :create, project.id, survey.id), file: file
      end
    end

    test "forbids upload if project is archived", %{conn: conn, user: user}  do
      project = insert(:project, archived: true)
      insert(:project_membership, user: user, project: project, level: "owner")
      survey = insert(:survey, project: project)

      file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers.csv", filename: "phone_numbers.csv"}
      assert_error_sent :forbidden, fn ->
        post conn, project_survey_respondent_group_path(conn, :create, project.id, survey.id), file: file
      end
    end
  end

  describe "update" do
    test "update group channels", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())
      group = insert(:respondent_group, survey: survey, respondents_count: 1)
      channel = insert(:channel, name: "test")

      attrs = %{channels: [%{id: channel.id, mode: channel.type}]}
      conn = put conn, project_survey_respondent_group_path(conn, :update, project.id, survey.id, group.id), respondent_group: attrs
      assert json_response(conn, 200)["data"] == %{
        "id" => group.id,
        "name" => group.name,
        "sample" => group.sample,
        "respondents_count" => group.respondents_count,
        "channels" => [%{"id" => channel.id, "mode" => channel.type}],
      }

      group = RespondentGroup
      |> Repo.get!(group.id)
      |> Repo.preload(:channels)

      channel_ids = group.channels
      |> Enum.map(&(&1.id))

      assert channel_ids == [channel.id]
    end

    test "it doesn't updates the group channels when the survey is running", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "running", schedule: completed_schedule())
      group = insert(:respondent_group, survey: survey, respondents_count: 1)
      channel = insert(:channel, name: "test")

      attrs = %{channels: [%{id: channel.id, mode: channel.type}]}
      conn = put conn, project_survey_respondent_group_path(conn, :update, project.id, survey.id, group.id), respondent_group: attrs
      assert response(conn, 422)

      group = RespondentGroup
      |> Repo.get!(group.id)
      |> Repo.preload(:channels)

      channel_ids = group.channels
      |> Enum.map(&(&1.id))

      assert channel_ids == []
    end

    test "forbids to update group channels if project is archived", %{conn: conn, user: user} do
      project = create_project_for_user(user, archived: true)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())
      group = insert(:respondent_group, survey: survey, respondents_count: 1)
      channel = insert(:channel, name: "test")

      attrs = %{channels: [%{id: channel.id, mode: channel.type}]}

      assert_error_sent :forbidden, fn ->
        put conn, project_survey_respondent_group_path(conn, :update, project.id, survey.id, group.id), respondent_group: attrs
      end
    end
  end

  describe "delete" do
    test "deletes a group", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      {:ok, local_time } = Ecto.DateTime.cast :calendar.local_time()
      group = insert(:respondent_group, survey: survey)

      entries = File.stream!("test/fixtures/respondent_phone_numbers.csv") |>
      CSV.decode(separator: ?\t) |>
      Enum.map(fn row ->
        %{phone_number: Enum.at(row, 0), survey_id: survey.id, respondent_group_id: group.id, inserted_at: local_time, updated_at: local_time, disposition: "registered", stats: %Stats{}}
      end)

      {respondents_count, _ } = Repo.insert_all(Respondent, entries)

      all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
      assert length(all) == respondents_count

      conn = delete conn, project_survey_respondent_group_path(conn, :delete, survey.project.id, survey.id, group.id)
      assert response(conn, 200)

      group = RespondentGroup |> Repo.get_by(survey_id: survey.id)
      refute group

      all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
      assert length(all) == 0
    end

    test "it doesn't deletes a group when the survey is running", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: "running")
      {:ok, local_time } = Ecto.DateTime.cast :calendar.local_time()
      group = insert(:respondent_group, survey: survey)

      entries = File.stream!("test/fixtures/respondent_phone_numbers.csv") |>
      CSV.decode(separator: ?\t) |>
      Enum.map(fn row ->
        %{phone_number: Enum.at(row, 0), survey_id: survey.id, respondent_group_id: group.id, inserted_at: local_time, updated_at: local_time, disposition: "registered", stats: %Stats{}}
      end)

      {respondents_count, _ } = Repo.insert_all(Respondent, entries)

      all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
      assert length(all) == respondents_count

      conn = delete conn, project_survey_respondent_group_path(conn, :delete, survey.project.id, survey.id, group.id)
      assert response(conn, 422)

      group = RespondentGroup |> Repo.get_by(survey_id: survey.id)
      assert group

      all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
      assert length(all) == respondents_count
    end

    test "updates project updated_at when deleting", %{conn: conn, user: user}  do
      {:ok, datetime, _} = DateTime.from_iso8601("2000-01-01T00:00:00Z")
      project = create_project_for_user(user, updated_at: datetime)
      survey = insert(:survey, project: project)
      group = insert(:respondent_group, survey: survey)

      delete conn, project_survey_respondent_group_path(conn, :delete, survey.project.id, survey.id, group.id)

      project = Project |> Repo.get(project.id)
      assert DateTime.compare(project.updated_at, datetime) == :gt
    end

    test "forbids the deletion of a group if the project is from another user", %{conn: conn} do
      project = insert(:project)
      survey = insert(:survey, project: project)
      group = insert(:respondent_group, survey: survey)

      assert_error_sent :forbidden, fn ->
        delete conn, project_survey_respondent_group_path(conn, :delete, survey.project.id, survey.id, group.id)
      end
    end

    test "forbids the deletion of a group for project reader", %{conn: conn, user: user} do
      project = insert(:project)
      insert(:project_membership, user: user, project: project, level: "reader")
      survey = insert(:survey, project: project)
      group = insert(:respondent_group, survey: survey)

      assert_error_sent :forbidden, fn ->
        delete conn, project_survey_respondent_group_path(conn, :delete, survey.project.id, survey.id, group.id)
      end
    end

    test "forbids the deletion of a group if project is archived", %{conn: conn, user: user} do
      project = insert(:project, archived: true)
      insert(:project_membership, user: user, project: project, level: "owner")
      survey = insert(:survey, project: project)
      group = insert(:respondent_group, survey: survey)

      assert_error_sent :forbidden, fn ->
        delete conn, project_survey_respondent_group_path(conn, :delete, survey.project.id, survey.id, group.id)
      end
    end

    test "updates survey state if all the respondents are deleted from a 'ready' survey", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())
      group = insert(:respondent_group, survey: survey, respondents_count: 1)

      channel = insert(:channel, name: "test")
      add_channel_to(group, channel)

      insert(:respondent, phone_number: "12345678", survey: survey, respondent_group: group)

      assert survey.state == "ready"

      conn = delete conn, project_survey_respondent_group_path(conn, :delete, survey.project.id, survey.id, group.id)
      assert response(conn, 200)

      new_survey = Repo.get(Ask.Survey, survey.id)

      assert new_survey.state == "not_ready"
    end
  end

  describe "add" do
    test "uploads CSV with more respondents", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      perform_add_test_for_survey(conn, project, survey)
    end

    test "uploads CSV with more respondents even if the survey is running", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: "running")
      perform_add_test_for_survey(conn, project, survey)
    end

    def perform_add_test_for_survey(conn, project, survey) do
      group = insert(:respondent_group, survey: survey, respondents_count: 2, sample: ["9988776655", "(549) 11 4234 2343"])

      # This doesn't exist in the uploaded csv
      insert(:respondent, survey: survey, respondent_group: group, phone_number: "9988776655", sanitized_phone_number: "9988776655")

      # This exists, so we expect no duplicates for this
      insert(:respondent, survey: survey, respondent_group: group, phone_number: "(549) 11 4234 2343", sanitized_phone_number: "5491142342343")

      file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers.csv", filename: "phone_numbers.csv"}

      conn = post conn, project_survey_respondent_group_add_path(conn, :add, project.id, survey.id, group.id), file: file
      group = RespondentGroup |> Repo.get(group.id)

      sample = ["######6655", "(###) ## #### 2343", "(###) ## #### 3125", "(###) ## #### 2323", "(###) ## #### 2421"]
      |> Enum.map(&Respondent.mask_phone_number/1)

      assert json_response(conn, 200)["data"] == %{
        "id" => group.id,
        "name" => group.name,
        "sample" => sample,
        "respondents_count" => 15,
        "channels" => [],
      }

      respondents = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)

      assert length(respondents) == 15

      assert group
      assert group.respondents_count == 15
      assert group.sample == respondents |> Enum.take(5) |> Enum.map(&(&1.phone_number))

      assert Enum.at(respondents, 2).survey_id == survey.id
      assert Enum.at(respondents, 2).phone_number == "(549) 11 2421 3125"
      assert Enum.at(respondents, 2).sanitized_phone_number == "5491124213125"
      assert Enum.at(respondents, 2).respondent_group_id == group.id
    end
  end

  describe "replace" do
    test "uploads CSV that replaces respondents", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      group = insert(:respondent_group, survey: survey, respondents_count: 1, sample: ["9988776655"])
      insert(:respondent, survey: survey, respondent_group: group, phone_number: "9988776655", sanitized_phone_number: "9988776655")

      file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers.csv", filename: "phone_numbers.csv"}

      conn = post conn, project_survey_respondent_group_replace_path(conn, :replace, project.id, survey.id, group.id), file: file
      group = RespondentGroup |> Repo.get(group.id)

      sample = ["(###) ## #### 2343", "(###) ## #### 3125", "(###) ## #### 2323", "(###) ## #### 2421", "(###) ## #### 6723"]

      assert json_response(conn, 200)["data"] == %{
        "id" => group.id,
        "name" => group.name,
        "sample" => sample,
        "respondents_count" => 14,
        "channels" => [],
      }

      respondents = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)

      assert length(respondents) == 14

      assert group
      assert group.respondents_count == 14
      assert group.sample == respondents |> Enum.take(5) |> Enum.map(&(&1.phone_number))

      assert Enum.at(respondents, 0).survey_id == survey.id
      assert Enum.at(respondents, 0).phone_number == "(549) 11 4234 2343"
      assert Enum.at(respondents, 0).sanitized_phone_number == "5491142342343"
      assert Enum.at(respondents, 0).respondent_group_id == group.id
    end
  end

  defp completed_schedule() do
    Ask.Schedule.always()
  end

  defp add_channel_to(group = %RespondentGroup{}, channel = %Channel{}) do
    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: channel.type})
    |> Repo.insert
  end
end
