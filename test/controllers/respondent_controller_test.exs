defmodule Ask.RespondentControllerTest do

  use Ask.ConnCase

  alias Ask.{Project, Respondent}

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
      project = insert(:project, user: user)
      survey = insert(:survey, project: project)
      conn = get conn, project_survey_respondent_path(conn, :index, project.id, survey.id)
      assert json_response(conn, 200)["data"]["respondents"] == []
      assert json_response(conn, 200)["meta"]["count"] == 0
    end

    test "fetches responses on index", %{conn: conn, user: user} do
      project = insert(:project, user: user)
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
    project = insert(:project, user: user)
    survey = insert(:survey, project: project, cutoff: 10)
    insert_list(10, :respondent, survey: survey, state: "pending")
    insert(:respondent, survey: survey, state: "completed", completed_at: Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}"))
    insert(:respondent, survey: survey, state: "completed", completed_at: Timex.parse!("2016-01-01T11:00:00Z", "{ISO:Extended}"))
    insert_list(3, :respondent, survey: survey, state: "completed", completed_at: Timex.parse!("2016-01-02T10:00:00Z", "{ISO:Extended}"))

    conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)

    assert json_response(conn, 200)["data"] == %{
      "id" => survey.id,
      "respondents_by_state" => %{
        "pending" => 10,
        "completed" => 5,
        "active" => 0,
        "failed" => 0
      },
      "completed_by_date" => %{
        "respondents_by_date" => [
          %{
            "date" => "2016-01-01",
            "count" => 2
          },
          %{
            "date" => "2016-01-02",
            "count" => 3
          }
        ],
        "target_value" => 10
      }
    }
  end

  test "target_value field equals respondents count when cutoff is not defined", %{conn: conn, user: user} do
    project = insert(:project, user: user)
    survey = insert(:survey, project: project)
    insert_list(5, :respondent, survey: survey, state: "pending")

    conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)

    assert json_response(conn, 200)["data"] == %{
      "id" => survey.id,
      "respondents_by_state" => %{
        "pending" => 5,
        "completed" => 0,
        "active" => 0,
        "failed" => 0
      },
      "completed_by_date" => %{
        "respondents_by_date" => [],
        "target_value" => 5
      }
    }
  end

  test "uploads CSV file with phone numbers and creates and renders resource when data is valid", %{conn: conn, user: user} do
    project = insert(:project, user: user)
    survey = insert(:survey, project: project)

    file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers.csv", filename: "phone_numbers.csv"}

    conn = post conn, project_survey_respondent_path(conn, :create, project.id, survey.id), file: file
    assert length(json_response(conn, 201)["data"]["respondents"]) == 5
    assert json_response(conn, 201)["meta"]["count"] == 14

    all = Repo.all(from r in Respondent, where: r.survey_id == ^survey.id)
    assert length(all) == 14
    assert Enum.at(all, 0).survey_id == survey.id
    assert Enum.at(all, 0).phone_number == "(549) 11 4234 2343"
  end

  test "uploads CSV file with phone numbers rejecting duplicated entries", %{conn: conn, user: user} do
    project = insert(:project, user: user)
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
    project = insert(:project, user: user)
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
    project = insert(:project, user: user)
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
    project = insert(:project, user: user)

    questionnaire = insert(:questionnaire, name: "test", project: project)
    survey = insert(:survey, project: project, cutoff: 4, questionnaire_id: questionnaire.id, schedule_day_of_week: completed_schedule)
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
    project = insert(:project, user: user, updated_at: datetime)
    survey = insert(:survey, project: project)

    file = %Plug.Upload{path: "test/fixtures/respondent_phone_numbers.csv", filename: "phone_numbers.csv"}
    post conn, project_survey_respondent_path(conn, :create, project.id, survey.id), file: file

    project = Project |> Repo.get(project.id)
    assert Ecto.DateTime.compare(project.updated_at, datetime) == :gt
  end

  test "deletes all the respondents from a survey", %{conn: conn, user: user} do
    project = insert(:project, user: user)
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
    project = insert(:project, user: user, updated_at: datetime)
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
    project = insert(:project, user: user)
    questionnaire = insert(:questionnaire, name: "test", project: project)
    survey = insert(:survey, project: project, cutoff: 4, questionnaire_id: questionnaire.id, state: "ready", schedule_day_of_week: completed_schedule)
    channel = insert(:channel, name: "test")

    add_channel_to(survey, channel)
    insert(:respondent, phone_number: "12345678", survey: survey)

    assert survey.state == "ready"

    conn = delete conn, project_survey_respondent_path(conn, :delete, survey.project.id, survey.id, -1)
    assert response(conn, 200)

    new_survey = Repo.get(Ask.Survey, survey.id)

    assert new_survey.state == "not_ready"
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
