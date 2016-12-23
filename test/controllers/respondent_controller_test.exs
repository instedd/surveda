defmodule Ask.RespondentControllerTest do

  use Ask.ConnCase
  use Ask.TestHelpers

  alias Ask.{Project, Respondent, QuotaBucket, Survey}

  @valid_attrs %{phone_number: "some content"}
  @invalid_attrs %{}

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
      conn = get conn, project_survey_respondent_path(conn, :index, project.id, survey.id)
      assert json_response(conn, 200)["data"]["respondents"] == []
      assert json_response(conn, 200)["meta"]["count"] == 0
    end

    test "fetches responses on index", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      respondent = insert(:respondent, survey: survey)
      response = insert(:response, respondent: respondent, value: "Yes")
      conn = get conn, project_survey_respondent_path(conn, :index, project.id, survey.id)
      assert json_response(conn, 200)["data"]["respondents"] == [%{
                                                     "id" => respondent.id,
                                                     "phone_number" => Respondent.mask_phone_number(respondent.phone_number),
                                                     "survey_id" => survey.id,
                                                     "date" => Ecto.DateTime.to_iso8601(response.updated_at),
                                                     "responses" => [
                                                       %{
                                                         "value" => response.value,
                                                         "name" => response.field_name
                                                       }
                                                     ]
                                                  }]
    end

    test "forbid index access if the project does not belong to the current user", %{conn: conn} do
      survey = insert(:survey)
      respondent = insert(:respondent, survey: survey)
      insert(:response, respondent: respondent, value: "Yes")
      assert_error_sent :forbidden, fn ->
        get conn, project_survey_respondent_path(conn, :index, survey.project.id, survey.id)
      end
    end

  end

  test "lists stats for a given survey", %{conn: conn, user: user} do
    t = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
    project = create_project_for_user(user)
    survey = insert(:survey, project: project, cutoff: 10, started_at: t)
    insert_list(10, :respondent, survey: survey, state: "pending")
    insert(:respondent, survey: survey, state: "completed", completed_at: Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}"))
    insert(:respondent, survey: survey, state: "completed", completed_at: Timex.parse!("2016-01-01T11:00:00Z", "{ISO:Extended}"))
    insert_list(3, :respondent, survey: survey, state: "completed", completed_at: Timex.parse!("2016-01-02T10:00:00Z", "{ISO:Extended}"))

    conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)

    assert json_response(conn, 200)["data"]["id"] == survey.id
    assert json_response(conn, 200)["data"]["respondents_by_state"] == %{
      "pending" => %{"count" => 10, "percent" => 66.66666666666667},
      "active" => %{"count" => 0, "percent" => 0.0},
      "completed" => %{"count" => 5, "percent" => 33.333333333333336},
      "failed" => %{"count" => 0, "percent" => 0.0},
      "stalled" => %{"count" => 0, "percent" => 0.0}
    }
    assert Enum.at(json_response(conn, 200)["data"]["respondents_by_date"], 0)["date"] == "2016-01-01"
    assert Enum.at(json_response(conn, 200)["data"]["respondents_by_date"], 0)["count"] == 2
    assert Enum.at(json_response(conn, 200)["data"]["respondents_by_date"], 1)["date"] == "2016-01-02"
    assert Enum.at(json_response(conn, 200)["data"]["respondents_by_date"], 1)["count"] == 3
    assert json_response(conn, 200)["data"]["total_respondents"] == 15
    assert json_response(conn, 200)["data"]["cutoff"] == 10
  end

  test "first value of respondents by date corresponds to started_at date", %{conn: conn, user: user} do
    t = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
    project = create_project_for_user(user)
    survey = insert(:survey, project: project, cutoff: 10, started_at: t)
    insert_list(10, :respondent, survey: survey, state: "pending")

    conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)

    assert (List.first(json_response(conn, 200)["data"]["respondents_by_date"])["date"]) == "2016-01-01"
  end

  test "fills dates when any respondent completed the survey with 0's", %{conn: conn, user: user} do
    t = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
    project = create_project_for_user(user)
    survey = insert(:survey, project: project, cutoff: 10, started_at: t)
    insert_list(10, :respondent, survey: survey, state: "pending")
    insert(:respondent, survey: survey, state: "completed", completed_at: Timex.parse!("2016-01-03T10:00:00Z", "{ISO:Extended}"))

    conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)
    date_with_no_respondents = Enum.at(json_response(conn, 200)["data"]["respondents_by_date"], 1)

    assert date_with_no_respondents["date"] == "2016-01-02"
    assert date_with_no_respondents["count"] == 0
  end

  test "target_value field equals respondents count when cutoff is not defined", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project)
    insert_list(5, :respondent, survey: survey, state: "pending")

    conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)

    assert json_response(conn, 200)["data"] == %{
      "id" => survey.id,
      "respondents_by_state" => %{
        "pending" => %{"count" => 5, "percent" => 100.0},
        "completed" => %{"count" => 0, "percent" => 0.0},
        "active" => %{"count" => 0, "percent" => 0.0},
        "failed" => %{"count" => 0, "percent" => 0.0},
        "stalled" => %{"count" => 0, "percent" => 0.0}
      },
      "respondents_by_date" => [],
      "cutoff" => nil,
      "total_respondents" => 5
    }
  end

  test "uploads CSV file with phone numbers and creates and renders resource when data is valid", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project)

    file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers.csv", filename: "phone_numbers.csv"}

    conn = post conn, project_survey_respondent_path(conn, :create, project.id, survey.id), file: file
    assert length(json_response(conn, 201)["data"]["respondents"]) == 5
    assert json_response(conn, 201)["meta"]["count"] == 14

    all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
    assert length(all) == 14
    assert Enum.at(all, 0).survey_id == survey.id
    assert Enum.at(all, 0).phone_number == "(549) 11 4234 2343"
    assert Enum.at(all, 0).sanitized_phone_number == "5491142342343"
  end

  test "uploads CSV file with phone numbers ignoring additional columns", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project)

    file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers_additional_columns.csv", filename: "phone_numbers.csv"}

    conn = post conn, project_survey_respondent_path(conn, :create, project.id, survey.id), file: file
    assert length(json_response(conn, 201)["data"]["respondents"]) == 5
    assert json_response(conn, 201)["meta"]["count"] == 14

    all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
    assert length(all) == 14
    assert Enum.at(all, 0).survey_id == survey.id
    assert Enum.at(all, 0).phone_number == "(549) 11 4234 2343"
  end

  test "uploads CSV file with single line", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project)

    file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers_one.csv", filename: "phone_numbers.csv"}

    conn = post conn, project_survey_respondent_path(conn, :create, project.id, survey.id), file: file
    assert length(json_response(conn, 201)["data"]["respondents"]) == 1
    assert json_response(conn, 201)["meta"]["count"] == 1

    all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
    assert length(all) == 1
    assert Enum.at(all, 0).survey_id == survey.id
    assert Enum.at(all, 0).phone_number == "123456789"
  end

  test "uploads CSV file with phone and creates and renders resource when data contains special characters but is valid", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project)

    file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers_special_characters.csv", filename: "phone_numbers.csv"}

    conn = post conn, project_survey_respondent_path(conn, :create, project.id, survey.id), file: file
    assert conn.status == 201
    all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
    assert length(all) == 3
    assert Enum.at(all, 0).phone_number == "+154 11 1213 2345"
  end

  test "uploads CSV file with phone numbers but does not create and render resource when numbers contains invalid characters", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project)

    file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers_invalid.csv", filename: "phone_numbers.csv"}

    conn = post conn, project_survey_respondent_path(conn, :create, project.id, survey.id), file: file
    assert conn.status == 422
    all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
    assert length(all) == 0
  end

  test "uploads CSV file with phone numbers rejecting duplicated entries", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project)

    file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers_duplicated.csv", filename: "phone_numbers.csv"}

    conn = post conn, project_survey_respondent_path(conn, :create, project.id, survey.id), file: file
    assert length(json_response(conn, 201)["data"]["respondents"]) == 5
    assert json_response(conn, 201)["meta"]["count"] == 16

    all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
    assert length(all) == 16
    assert Enum.at(all, 0).survey_id == survey.id
    assert Enum.at(all, 0).phone_number == "(549) 11 4234 2343"
  end

  test "it supports \r as a field separator", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project)

    file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers_r.csv", filename: "phone_numbers.csv"}

    conn = post conn, project_survey_respondent_path(conn, :create, project.id, survey.id), file: file
    assert length(json_response(conn, 201)["data"]["respondents"]) == 4

    all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
    assert length(all) == 4
    assert Enum.at(all, 0).survey_id == survey.id
    assert Enum.at(all, 0).phone_number == "15044020205"
  end

  test "it supports \n as a field separator", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project)

    file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers_newline.csv", filename: "phone_numbers.csv"}

    conn = post conn, project_survey_respondent_path(conn, :create, project.id, survey.id), file: file
    assert length(json_response(conn, 201)["data"]["respondents"]) == 4

    all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
    assert length(all) == 4
    assert Enum.at(all, 0).survey_id == survey.id
    assert Enum.at(all, 0).phone_number == "15044020205"
  end

  test "updates survey state if the respondents CSV upload is the only remaining step on the survey wizard", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    questionnaire = insert(:questionnaire, name: "test", project: project)
    survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], schedule_day_of_week: completed_schedule, mode: [["sms"]])
    channel = insert(:channel, name: "test")

    add_channel_to(survey, channel)

    assert survey.state == "not_ready"

    file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers.csv", filename: "phone_numbers.csv"}

    post conn, project_survey_respondent_path(conn, :create, project.id, survey.id), file: file

    new_survey = Repo.get(Ask.Survey, survey.id)

    assert new_survey.state == "ready"
  end

  test "updates project updated_at when uploading CSV", %{conn: conn, user: user}  do
    datetime = Ecto.DateTime.cast!("2000-01-01 00:00:00")
    project = insert(:project, updated_at: datetime)
    insert(:project_membership, user: user, project: project, level: "owner")
    survey = insert(:survey, project: project)

    file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers.csv", filename: "phone_numbers.csv"}
    post conn, project_survey_respondent_path(conn, :create, project.id, survey.id), file: file

    project = Project |> Repo.get(project.id)
    assert Ecto.DateTime.compare(project.updated_at, datetime) == :gt
  end

  test "deletes all the respondents from a survey", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project)
    {:ok, local_time } = Ecto.DateTime.cast :calendar.local_time()

    entries = File.stream!("test/fixtures/respondent_phone_numbers.csv") |>
    CSV.decode(separator: ?\t) |>
    Enum.map(fn row ->
      %{phone_number: Enum.at(row, 0), survey_id: survey.id, inserted_at: local_time, updated_at: local_time}
    end)

    {respondents_count, _ } = Repo.insert_all(Respondent, entries)

    all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
    assert length(all) == respondents_count

    conn = delete conn, project_survey_respondent_path(conn, :delete, survey.project.id, survey.id, -1)
    assert response(conn, 200)

    all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
    assert length(all) == 0
  end

  test "updates project updated_at when deleting", %{conn: conn, user: user}  do
    datetime = Ecto.DateTime.cast!("2000-01-01 00:00:00")
    project = insert(:project, updated_at: datetime)
    insert(:project_membership, user: user, project: project, level: "owner")
    survey = insert(:survey, project: project)

    delete conn, project_survey_respondent_path(conn, :delete, survey.project.id, survey.id, -1)

    project = Project |> Repo.get(project.id)
    assert Ecto.DateTime.compare(project.updated_at, datetime) == :gt
  end

  test "forbids the deleteion of all the respondents from a survey if the project is from another user", %{conn: conn} do
    project = insert(:project)
    survey = insert(:survey, project: project)
    {:ok, local_time } = Ecto.DateTime.cast :calendar.local_time()

    entries = File.stream!("test/fixtures/respondent_phone_numbers.csv") |>
      CSV.decode(separator: ?\t) |>
      Enum.map(fn row ->
        %{phone_number: Enum.at(row, 0), survey_id: survey.id, inserted_at: local_time, updated_at: local_time}
      end)

    {respondents_count, _ } = Repo.insert_all(Respondent, entries)

    all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
    assert length(all) == respondents_count

    assert_error_sent :forbidden, fn ->
      delete conn, project_survey_respondent_path(conn, :delete, survey.project.id, survey.id, -1)
    end
  end

  test "updates survey state if the respondents are deleted from a 'ready' survey", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    questionnaire = insert(:questionnaire, name: "test", project: project)
    survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule_day_of_week: completed_schedule)
    channel = insert(:channel, name: "test")

    add_channel_to(survey, channel)
    insert(:respondent, phone_number: "12345678", survey: survey)

    assert survey.state == "ready"

    conn = delete conn, project_survey_respondent_path(conn, :delete, survey.project.id, survey.id, -1)
    assert response(conn, 200)

    new_survey = Repo.get(Ask.Survey, survey.id)

    assert new_survey.state == "not_ready"
  end

  test "download csv", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    questionnaire = insert(:questionnaire, name: "test", project: project)
    survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule_day_of_week: completed_schedule)
    respondent_1 = insert(:respondent, survey: survey)
    insert(:response, respondent: respondent_1, field_name: "Smoke", value: "Yes")
    insert(:response, respondent: respondent_1, field_name: "Drink", value: "No")
    respondent_2 = insert(:respondent, survey: survey)
    insert(:response, respondent: respondent_2, field_name: "Smoke", value: "No")

    conn = get conn, project_survey_respondents_csv_path(conn, :csv, survey.project.id, survey.id, %{"offset" => "0"})
    csv = response(conn, 200)

    [line1, line2, line3, _] = csv |> String.split("\r\n")
    assert line1 == "Respondent ID,Smoke,Drink,Date"

    [line_2_id, line_2_smoke, line_2_drink, _] = line2 |> String.split(",", parts: 4)
    assert line_2_id == respondent_1.id |> to_string
    assert line_2_smoke == "Yes"
    assert line_2_drink == "No"

    [line_3_id, line_3_smoke, line_3_drink, _] = line3 |> String.split(",", parts: 4)
    assert line_3_id == respondent_2.id |> to_string
    assert line_3_smoke == "No"
    assert line_3_drink == ""
  end

  test "quotas_stats", %{conn: conn, user: user} do
    t = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
    project = create_project_for_user(user)

    quotas = %{
      "vars" => ["Smokes", "Exercises"],
      "buckets" => [
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "No"}],
          "quota" => 1,
          "count" => 1
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "Yes"}],
          "quota" => 4,
          "count" => 2
        },
      ]
    }

    survey = insert(:survey, project: project, started_at: t)
    survey = survey
    |> Repo.preload([:quota_buckets])
    |> Survey.changeset(%{quotas: quotas})
    |> Repo.update!

    qb1 = (from q in QuotaBucket, where: q.quota == 1) |> Repo.one
    qb4 = (from q in QuotaBucket, where: q.quota == 4) |> Repo.one

    insert(:respondent, survey: survey, state: "completed", quota_bucket_id: qb1.id, completed_at: Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}"))
    insert(:respondent, survey: survey, state: "completed", quota_bucket_id: qb4.id, completed_at: Timex.parse!("2016-01-01T11:00:00Z", "{ISO:Extended}"))
    insert(:respondent, survey: survey, state: "active", quota_bucket_id: qb4.id, completed_at: Timex.parse!("2016-01-01T11:00:00Z", "{ISO:Extended}"))

    conn = get conn, project_survey_respondents_quotas_stats_path(conn, :quotas_stats, project.id, survey.id)
    assert json_response(conn, 200) == %{"data" =>
      [%{"condition" => %{"Exercises" => "No", "Smokes" => "No"}, "count" => 1,
         "full" => 1, "partials" => 0, "quota" => 1},
       %{"condition" => %{"Exercises" => "Yes", "Smokes" => "No"}, "count" => 2,
         "full" => 1, "partials" => 1, "quota" => 4}]}
  end

  def completed_schedule do
    %Ask.DayOfWeek{sun: false, mon: true, tue: true, wed: false, thu: false, fri: false, sat: false}
  end

  def add_channel_to(survey, channel) do
    channels_changeset = Repo.get!(Ask.Channel, channel.id) |> change

    changeset = survey
    |> Repo.preload([:channels])
    |> Ecto.Changeset.change
    |> put_assoc(:channels, [channels_changeset])

    Repo.update(changeset)
  end
end
