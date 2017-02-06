defmodule Ask.RespondentControllerTest do

  use Ask.ConnCase
  use Ask.TestHelpers

  alias Ask.{Respondent, QuotaBucket, Survey}

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
      questionnaire = insert(:questionnaire, project: project)
      respondent = insert(:respondent, survey: survey, mode: ["sms"], questionnaire_id: questionnaire.id, disposition: "completed")
      response = insert(:response, respondent: respondent, value: "Yes")
      conn = get conn, project_survey_respondent_path(conn, :index, project.id, survey.id)
      assert json_response(conn, 200)["data"]["respondents"] == [%{
                                                     "id" => respondent.id,
                                                     "phone_number" => Respondent.mask_phone_number(respondent.phone_number),
                                                     "survey_id" => survey.id,
                                                     "mode" => ["sms"],
                                                     "questionnaire_id" => questionnaire.id,
                                                     "disposition" => "completed",
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
    assert Enum.at(json_response(conn, 200)["data"]["respondents_by_date"], 1)["count"] == 5
    assert json_response(conn, 200)["data"]["total_respondents"] == 15
    assert json_response(conn, 200)["data"]["cutoff"] == 10
  end

  test "lists stats for a given survey with quotas", %{conn: conn, user: user} do
    t = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
    project = create_project_for_user(user)
    survey = insert(:survey, project: project, cutoff: 10, started_at: t)
    bucket_1 = insert(:quota_bucket, survey: survey, quota: 4, count: 2)
    bucket_2 = insert(:quota_bucket, survey: survey, quota: 3, count: 3)
    insert_list(10, :respondent, survey: survey, state: "pending")
    insert(:respondent, survey: survey, state: "completed", completed_at: Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}"), quota_bucket: bucket_1)
    insert(:respondent, survey: survey, state: "completed", completed_at: Timex.parse!("2016-01-01T11:00:00Z", "{ISO:Extended}"), quota_bucket: bucket_1)
    insert_list(4, :respondent, survey: survey, state: "completed", completed_at: Timex.parse!("2016-01-02T10:00:00Z", "{ISO:Extended}"), quota_bucket: bucket_2)

    conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)

    assert json_response(conn, 200)["data"]["id"] == survey.id
    assert json_response(conn, 200)["data"]["respondents_by_state"] == %{
      "pending" => %{"count" => 10, "percent" => 62.5},
      "active" => %{"count" => 0, "percent" => 0.0},
      "completed" => %{"count" => 6, "percent" => 37.5},
      "failed" => %{"count" => 0, "percent" => 0.0},
      "stalled" => %{"count" => 0, "percent" => 0.0}
    }

    assert Enum.at(json_response(conn, 200)["data"]["respondents_by_date"], 0)["date"] == "2016-01-01"
    assert Enum.at(json_response(conn, 200)["data"]["respondents_by_date"], 0)["count"] == 2
    assert Enum.at(json_response(conn, 200)["data"]["respondents_by_date"], 1)["date"] == "2016-01-02"
    assert Enum.at(json_response(conn, 200)["data"]["respondents_by_date"], 1)["count"] == 5
    assert json_response(conn, 200)["data"]["total_respondents"] == 16
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
      "total_quota" => 0,
      "total_respondents" => 5
    }
  end

  test "download csv", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    questionnaire = insert(:questionnaire, name: "test", project: project)
    survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule_day_of_week: completed_schedule)
    respondent_1 = insert(:respondent, survey: survey, hashed_number: "1asd12451eds", disposition: "partial")
    insert(:response, respondent: respondent_1, field_name: "Smoke", value: "Yes")
    insert(:response, respondent: respondent_1, field_name: "Drink", value: "No")
    respondent_2 = insert(:respondent, survey: survey, hashed_number: "34y5345tjyet")
    insert(:response, respondent: respondent_2, field_name: "Smoke", value: "No")

    conn = get conn, project_survey_respondents_csv_path(conn, :csv, survey.project.id, survey.id, %{"offset" => "0"})
    csv = response(conn, 200)

    [line1, line2, line3, _] = csv |> String.split("\r\n")
    assert line1 == "Respondent ID,Smoke,Drink,Disposition,Date"

    [line_2_hashed_number, line_2_smoke, line_2_drink, line_2_disp, _] = line2 |> String.split(",", parts: 5)
    assert line_2_hashed_number == respondent_1.hashed_number
    assert line_2_smoke == "Yes"
    assert line_2_drink == "No"
    assert line_2_disp == "Partial"

    [line_3_hashed_number, line_3_smoke, line_3_drink, line_3_disp,  _] = line3 |> String.split(",", parts: 5)
    assert line_3_hashed_number == respondent_2.hashed_number
    assert line_3_smoke == "No"
    assert line_3_drink == ""
    assert line_3_disp == ""
  end

  test "download csv with comparisons", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    questionnaire = insert(:questionnaire, name: "test", project: project)
    questionnaire2 = insert(:questionnaire, name: "test 2", project: project)
    survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire, questionnaire2], state: "ready", schedule_day_of_week: completed_schedule,
      comparisons: [
        %{"mode" => ["sms"], "questionnaire_id" => questionnaire.id, "ratio" => 50},
        %{"mode" => ["sms"], "questionnaire_id" => questionnaire2.id, "ratio" => 50},
      ]
    )
    respondent_1 = insert(:respondent, survey: survey, questionnaire_id: questionnaire.id, mode: ["sms"], disposition: "partial")
    insert(:response, respondent: respondent_1, field_name: "Smoke", value: "Yes")
    insert(:response, respondent: respondent_1, field_name: "Drink", value: "No")
    respondent_2 = insert(:respondent, survey: survey, questionnaire_id: questionnaire2.id, mode: ["sms", "ivr"], disposition: "completed")
    insert(:response, respondent: respondent_2, field_name: "Smoke", value: "No")

    conn = get conn, project_survey_respondents_csv_path(conn, :csv, survey.project.id, survey.id, %{"offset" => "0"})
    csv = response(conn, 200)

    [line1, line2, line3, _] = csv |> String.split("\r\n")
    assert line1 == "Respondent ID,Smoke,Drink,Variant,Disposition,Date"

    [line_2_hashed_number, line_2_smoke, line_2_drink, line_2_variant, line_2_disp, _] = line2 |> String.split(",", parts: 6)
    assert line_2_hashed_number == respondent_1.hashed_number |> to_string
    assert line_2_smoke == "Yes"
    assert line_2_drink == "No"
    assert line_2_variant == "test - SMS"
    assert line_2_disp == "Partial"

    [line_3_hashed_number, line_3_smoke, line_3_drink, line_3_variant, line_3_disp, _] = line3 |> String.split(",", parts: 6)
    assert line_3_hashed_number == respondent_2.hashed_number |> to_string
    assert line_3_smoke == "No"
    assert line_3_drink == ""
    assert line_3_variant == "test 2 - SMS with phone call fallback"
    assert line_3_disp == "Completed"
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
end
