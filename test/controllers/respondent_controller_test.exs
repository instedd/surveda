defmodule Ask.RespondentControllerTest do

  use Ask.ConnCase
  use Ask.TestHelpers
  use Ask.DummySteps

  alias Ask.{QuotaBucket, Survey}

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
                                                     "phone_number" => respondent.hashed_number,
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
    questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
    insert_list(10, :respondent, survey: survey, questionnaire: questionnaire, disposition: "partial")
    insert(:respondent, survey: survey, disposition: "completed", questionnaire: questionnaire, completed_at: Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}"))
    insert(:respondent, survey: survey, disposition: "completed", questionnaire: questionnaire, completed_at: Timex.parse!("2016-01-01T11:00:00Z", "{ISO:Extended}"))
    insert_list(3, :respondent, survey: survey, disposition: "completed", questionnaire: questionnaire, completed_at: Timex.parse!("2016-01-02T10:00:00Z", "{ISO:Extended}"))

    conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)
    data = json_response(conn, 200)["data"]
    total = 15.0

    string_questionnaire_id = to_string(questionnaire.id)

    assert data["id"] == survey.id
    assert data["respondents_by_disposition"] == %{
      "uncontacted" => %{
        "count" => 0,
        "percent" => 0.0,
        "detail" => %{
          "registered" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          "queued" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          "failed" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
        },
      },
      "contacted" => %{
        "count" => 0,
        "percent" => 0.0,
        "detail" => %{
          "contacted" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          "unresponsive" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
        },
      },
      "responsive" => %{
        "count" => 15,
        "percent" => 100.0,
        "detail" => %{
          "started" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          "breakoff" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          "partial" => %{"count" => 10, "percent" => 100*10/total, "by_questionnaire" => %{string_questionnaire_id => 10}},
          "completed" => %{"count" => 5, "percent" => 100*5/total, "by_questionnaire" => %{string_questionnaire_id => 5}},
          "ineligible" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          "refused" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          "rejected" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
        },
      },
    }

    cumulative_percentages = data["cumulative_percentages"][to_string(questionnaire.id)]

    assert Enum.at(cumulative_percentages, 0)["date"] == "2016-01-01"
    assert Enum.at(cumulative_percentages, 0)["percent"] == 20
    assert Enum.at(cumulative_percentages, 1)["date"] == "2016-01-02"
    assert Enum.at(cumulative_percentages, 1)["percent"] == 50
    assert data["total_respondents"] == 15
  end

  test "lists stats for a given survey with quotas", %{conn: conn, user: user} do
    t = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
    project = create_project_for_user(user)
    survey = insert(:survey, project: project, cutoff: 10, started_at: t)
    bucket_1 = insert(:quota_bucket, survey: survey, quota: 4, count: 2)
    bucket_2 = insert(:quota_bucket, survey: survey, quota: 3, count: 3)
    questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
    insert_list(10, :respondent, survey: survey, questionnaire: questionnaire, disposition: "partial")
    insert(:respondent, survey: survey, questionnaire: questionnaire, disposition: "completed", completed_at: Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}"), quota_bucket: bucket_1)
    insert(:respondent, survey: survey, questionnaire: questionnaire, disposition: "completed", completed_at: Timex.parse!("2016-01-01T11:00:00Z", "{ISO:Extended}"), quota_bucket: bucket_1)
    insert(:respondent, survey: survey, questionnaire: questionnaire, disposition: "rejected", completed_at: Timex.parse!("2016-01-02T10:00:00Z", "{ISO:Extended}"), quota_bucket: bucket_2)
    insert_list(3, :respondent, survey: survey, questionnaire: questionnaire, disposition: "completed", completed_at: Timex.parse!("2016-01-02T10:00:00Z", "{ISO:Extended}"), quota_bucket: bucket_2)

    conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)
    data = json_response(conn, 200)["data"]
    total = 16.0

    string_questionnaire_id = to_string(questionnaire.id)
    assert data["id"] == survey.id
    assert data["respondents_by_disposition"] == %{
      "uncontacted" => %{
        "count" => 0,
        "percent" => 0.0,
        "detail" => %{
          "registered" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          "queued" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          "failed" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
        },
      },
      "contacted" => %{
        "count" => 0,
        "percent" => 0.0,
        "detail" => %{
          "contacted" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          "unresponsive" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
        },
      },
      "responsive" => %{
        "count" => 16,
        "percent" => 100.0,
        "detail" => %{
          "started" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          "breakoff" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          "partial" => %{"count" => 10, "percent" => 100*10/total, "by_questionnaire" => %{string_questionnaire_id => 10}},
          "completed" => %{"count" => 5, "percent" => 100*5/total, "by_questionnaire" => %{string_questionnaire_id => 5}},
          "ineligible" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          "refused" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          "rejected" => %{"count" => 1, "percent" => 100*1/total, "by_questionnaire" => %{string_questionnaire_id => 1}},
        },
      },
    }

    cumulative_percentages = data["cumulative_percentages"][to_string(questionnaire.id)]

    assert Enum.at(cumulative_percentages, 0)["date"] == "2016-01-01"
    assert abs(Enum.at(cumulative_percentages, 0)["percent"] - 28) < 1
    assert Enum.at(cumulative_percentages, 1)["date"] == "2016-01-02"
    assert abs(Enum.at(cumulative_percentages, 1)["percent"] - 71) < 1
    assert data["total_respondents"] == 16
  end

  test "lists stats for a given survey, with dispositions", %{conn: conn, user: user} do
    t = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
    project = create_project_for_user(user)
    survey = insert(:survey, project: project, cutoff: 10, started_at: t)
    questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
    insert_list(10, :respondent, survey: survey, state: "pending", disposition: "registered")
    insert(:respondent, survey: survey, state: "completed", questionnaire: questionnaire, disposition: "partial", completed_at: Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}"))
    insert(:respondent, survey: survey, state: "completed", questionnaire: questionnaire, disposition: "completed", completed_at: Timex.parse!("2016-01-01T11:00:00Z", "{ISO:Extended}"))
    insert_list(3, :respondent, survey: survey, state: "completed", questionnaire: questionnaire, disposition: "ineligible", completed_at: Timex.parse!("2016-01-02T10:00:00Z", "{ISO:Extended}"))

    conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)
    data = json_response(conn, 200)["data"]
    total = 15.0

    string_questionnaire_id = to_string(questionnaire.id)
    assert data["id"] == survey.id
    assert data["respondents_by_disposition"] == %{
      "uncontacted" => %{
        "count" => 10,
        "percent" => 100*10/total,
        "detail" => %{
          "registered" => %{"count" => 10, "percent" => 100*10/total, "by_questionnaire" => %{"" => 10}},
          "queued" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          "failed" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
        },
      },
      "contacted" => %{
        "count" => 0,
        "percent" => 0.0,
        "detail" => %{
          "contacted" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          "unresponsive" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
        },
      },
      "responsive" => %{
        "count" => 5,
        "percent" => 100*5/total,
        "detail" => %{
          "started" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          "breakoff" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          "partial" => %{"count" => 1, "percent" => 100*1/total, "by_questionnaire" => %{string_questionnaire_id => 1}},
          "completed" => %{"count" => 1, "percent" => 100*1/total, "by_questionnaire" => %{string_questionnaire_id => 1}},
          "ineligible" => %{"count" => 3, "percent" => 100*3/total, "by_questionnaire" => %{string_questionnaire_id => 3}},
          "refused" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          "rejected" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
        },
      },
    }

    cumulative_percentages = data["cumulative_percentages"][to_string(questionnaire.id)]

    assert Enum.at(cumulative_percentages, 0)["date"] == "2016-01-01"
    assert Enum.at(cumulative_percentages, 0)["percent"] == 10
    assert Enum.at(cumulative_percentages, 1)["date"] == "2016-01-02"
    assert Enum.at(cumulative_percentages, 1)["percent"] == 10
    assert data["total_respondents"] == 15
    assert data["completion_percentage"] == 20
  end

  test "fills dates when any respondent completed the survey with 0's", %{conn: conn, user: user} do
    t = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
    project = create_project_for_user(user)
    survey = insert(:survey, project: project, cutoff: 10, started_at: t)
    questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
    insert_list(10, :respondent, survey: survey, state: "pending")
    insert(:respondent, survey: survey, questionnaire: questionnaire, state: "completed", disposition: "completed", completed_at: Timex.parse!("2016-01-03T10:00:00Z", "{ISO:Extended}"))

    conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)
    date_with_no_respondents =
      json_response(conn, 200)["data"]["cumulative_percentages"]
      |> Map.get(to_string(questionnaire.id))
      |> Enum.at(1)

    assert date_with_no_respondents["date"] == "2016-01-02"
    assert date_with_no_respondents["percent"] == 0
  end

  test "target_value field equals respondents count when cutoff is not defined", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project)
    insert_list(5, :respondent, survey: survey, state: "pending", disposition: "registered")

    conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)

    total = 5.0

    assert json_response(conn, 200)["data"] == %{
      "id" => survey.id,
      "respondents_by_disposition" => %{
        "uncontacted" => %{
          "count" => 5,
          "percent" => 100*5/total,
          "detail" => %{
            "registered" => %{"count" => 5, "percent" => 100*5/total, "by_questionnaire" => %{"" => 5}},
            "queued" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
            "failed" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          },
        },
        "contacted" => %{
          "count" => 0,
          "percent" => 0.0,
          "detail" => %{
            "contacted" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
            "unresponsive" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          },
        },
        "responsive" => %{
          "count" => 0,
          "percent" => 0.0,
          "detail" => %{
            "started" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
            "breakoff" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
            "partial" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
            "completed" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
            "ineligible" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
            "refused" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
            "rejected" => %{"count" => 0, "percent" => 0.0, "by_questionnaire" => %{}},
          },
        },
      },
      "cumulative_percentages" => %{},
      "total_respondents" => 5,
      "contacted_respondents" => 0,
      "completion_percentage" => 0
    }
  end

  test "download csv", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
    survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule_day_of_week: completed_schedule)
    respondent_1 = insert(:respondent, survey: survey, hashed_number: "1asd12451eds", disposition: "partial", effective_modes: ["sms", "ivr"])
    insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
    insert(:response, respondent: respondent_1, field_name: "Exercises", value: "No")
    respondent_2 = insert(:respondent, survey: survey, hashed_number: "34y5345tjyet", effective_modes: ["mobileweb"])
    insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")

    conn = get conn, project_survey_respondents_csv_path(conn, :csv, survey.project.id, survey.id, %{"offset" => "0"})
    csv = response(conn, 200)

    [line1, line2, line3, _] = csv |> String.split("\r\n")
    assert line1 == "Respondent ID,Date,Modes,Smokes,Exercises,Perfect Number,Question,Disposition"

    [line_2_hashed_number, _, line_2_modes, line_2_smoke, line_2_exercises, _, _, line_2_disp] = [line2] |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd

    assert line_2_hashed_number == respondent_1.hashed_number
    assert line_2_modes == "SMS, Phone call"
    assert line_2_smoke == "Yes"
    assert line_2_exercises == "No"
    assert line_2_disp == "Partial"

    [line_3_hashed_number, _, line_3_modes, line_3_smoke, line_3_exercises, _, _, line_3_disp] = [line3]  |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd
    assert line_3_hashed_number == respondent_2.hashed_number
    assert line_3_modes == "Mobile Web"
    assert line_3_smoke == "No"
    assert line_3_exercises == ""
    assert line_3_disp == "Registered"
  end

  test "download csv with comparisons", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
    questionnaire2 = insert(:questionnaire, name: "test 2", project: project, steps: @dummy_steps)
    survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire, questionnaire2], state: "ready", schedule_day_of_week: completed_schedule,
      comparisons: [
        %{"mode" => ["sms"], "questionnaire_id" => questionnaire.id, "ratio" => 50},
        %{"mode" => ["sms"], "questionnaire_id" => questionnaire2.id, "ratio" => 50},
      ]
    )
    respondent_1 = insert(:respondent, survey: survey, questionnaire_id: questionnaire.id, mode: ["sms"], disposition: "partial")
    insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
    insert(:response, respondent: respondent_1, field_name: "Perfect Number", value: "No")
    respondent_2 = insert(:respondent, survey: survey, questionnaire_id: questionnaire2.id, mode: ["sms", "ivr"], disposition: "completed")
    insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")

    conn = get conn, project_survey_respondents_csv_path(conn, :csv, survey.project.id, survey.id, %{"offset" => "0"})
    csv = response(conn, 200)

    [line1, line2, line3, _] = csv |> String.split("\r\n")
    assert line1 == "Respondent ID,Date,Modes,Smokes,Exercises,Perfect Number,Question,Variant,Disposition"

    [line_2_hashed_number, _, _, line_2_smoke, _, line_2_number, _, line_2_variant, line_2_disp] = [line2] |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd
    assert line_2_hashed_number == respondent_1.hashed_number |> to_string
    assert line_2_smoke == "Yes"
    assert line_2_number == "No"
    assert line_2_variant == "test - SMS"
    assert line_2_disp == "Partial"

    [line_3_hashed_number, _, _, line_3_smoke, _, line_3_number, _, line_3_variant, line_3_disp] = [line3] |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd
    assert line_3_hashed_number == respondent_2.hashed_number |> to_string
    assert line_3_smoke == "No"
    assert line_3_number == ""
    assert line_3_variant == "test 2 - SMS with phone call fallback"
    assert line_3_disp == "Completed"
  end

  test "download csv with language", %{conn: conn, user: user} do
    languageStep = %{
      "id" => "1234-5678",
      "type" => "language-selection",
      "title" => "Language selection",
      "store" => "language",
      "prompt" => %{
        "sms" => "1 for English, 2 for Spanish",
        "ivr" => %{
          "text" => "1 para ingles, 2 para español",
          "audioSource" => "tts",
        }
      },
      "language_choices" => ["en", "es"],
    }
    steps = [languageStep]

    project = create_project_for_user(user)
    questionnaire = insert(:questionnaire, name: "test", project: project, steps: steps)
    survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule_day_of_week: completed_schedule)
    respondent_1 = insert(:respondent, survey: survey, hashed_number: "1asd12451eds", disposition: "partial")
    insert(:response, respondent: respondent_1, field_name: "language", value: "es")

    conn = get conn, project_survey_respondents_csv_path(conn, :csv, survey.project.id, survey.id, %{"offset" => "0"})
    csv = response(conn, 200)

    [line1, line2, _] = csv |> String.split("\r\n")
    assert line1 == "Respondent ID,Date,Modes,language,Disposition"

    [line_2_hashed_number, _, _, line_2_language, _] = [line2] |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd
    assert line_2_hashed_number == respondent_1.hashed_number
    assert line_2_language == "español"
  end

  test "download disposition history csv", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    questionnaire = insert(:questionnaire, name: "test", project: project)
    survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule_day_of_week: completed_schedule)
    respondent_1 = insert(:respondent, survey: survey, hashed_number: "1asd12451eds", disposition: "partial")
    respondent_2 = insert(:respondent, survey: survey, hashed_number: "34y5345tjyet")

    insert(:respondent_disposition_history, respondent: respondent_1, disposition: "partial", mode: "sms", inserted_at: Ecto.DateTime.cast!("2000-01-01 01:02:03"))
    insert(:respondent_disposition_history, respondent: respondent_1, disposition: "completed",  mode: "sms",inserted_at: Ecto.DateTime.cast!("2000-01-01 02:03:04"))

    insert(:respondent_disposition_history, respondent: respondent_2, disposition: "partial", mode: "ivr", inserted_at: Ecto.DateTime.cast!("2000-01-01 03:04:05"))
    insert(:respondent_disposition_history, respondent: respondent_2, disposition: "completed", mode: "ivr", inserted_at: Ecto.DateTime.cast!("2000-01-01 04:05:06"))

    conn = get conn, project_survey_respondents_disposition_history_csv_path(conn, :disposition_history_csv, survey.project.id, survey.id)
    csv = response(conn, 200)

    lines = csv |> String.split("\r\n") |> Enum.reject(fn x -> String.length(x) == 0 end)
    assert lines == ["Respondent ID,Disposition,Mode,Timestamp",
     "1asd12451eds,partial,SMS,2000-01-01 01:02:03 UTC",
     "1asd12451eds,completed,SMS,2000-01-01 02:03:04 UTC",
     "34y5345tjyet,partial,Phone call,2000-01-01 03:04:05 UTC",
     "34y5345tjyet,completed,Phone call,2000-01-01 04:05:06 UTC"]
  end

  test "download incentives_csv", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    questionnaire = insert(:questionnaire, name: "test", project: project)
    survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule_day_of_week: completed_schedule)
    insert(:respondent, survey: survey, phone_number: "1234", disposition: "partial", questionnaire_id: questionnaire.id, mode: ["sms"])
    insert(:respondent, survey: survey, phone_number: "5678", disposition: "completed", questionnaire_id: questionnaire.id, mode: ["sms", "ivr"])
    insert(:respondent, survey: survey, phone_number: "9012", disposition: "completed", mode: ["sms", "ivr"])

    conn = get conn, project_survey_respondents_incentives_csv_path(conn, :incentives_csv, survey.project.id, survey.id)
    csv = response(conn, 200)

    lines = csv |> String.split("\r\n") |> Enum.reject(fn x -> String.length(x) == 0 end)
    assert lines == ["Telephone number,Questionnaire-Mode",
     "5678,test - SMS with phone call fallback"]
  end

  test "download interactions_csv", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    questionnaire = insert(:questionnaire, name: "test", project: project)
    survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule_day_of_week: completed_schedule)
    respondent_1 = insert(:respondent, survey: survey, hashed_number: "1234")
    respondent_2 = insert(:respondent, survey: survey, hashed_number: "5678")
    channel = insert(:channel, name: "test_channel")
    for _ <- 1..200 do
      insert(:survey_log_entry, survey: survey, mode: "sms",respondent: respondent_1, respondent_hashed_number: "5678", channel: channel, disposition: "completed", action_type: "prompt", action_data: "explanation", timestamp: Ecto.DateTime.cast!("2000-01-01 01:02:03"))
      insert(:survey_log_entry, survey: survey, mode: "ivr",respondent: respondent_2, respondent_hashed_number: "1234", channel: nil, disposition: "partial", action_type: "contact", action_data: "explanation", timestamp: Ecto.DateTime.cast!("2000-01-01 02:03:04"))
      insert(:survey_log_entry, survey: survey, mode: "mobileweb",respondent: respondent_2, respondent_hashed_number: "5678", channel: nil, disposition: "partial", action_type: "contact", action_data: "explanation", timestamp: Ecto.DateTime.cast!("2000-01-01 03:04:05"))
    end

    conn = get conn, project_survey_respondents_interactions_csv_path(conn, :interactions_csv, survey.project.id, survey.id)
    csv = response(conn, 200)

    expected_list = List.flatten(
      ["Respondent ID,Mode,Channel,Disposition,Action Type,Action Data,Timestamp",
      for _ <- 1..200 do
        "1234,IVR,,Partial,Contact attempt,explanation,2000-01-01 02:03:04 UTC"
      end,
      for _ <- 1..200 do
        ["5678,SMS,test_channel,Completed,Prompt,explanation,2000-01-01 01:02:03 UTC",
        "5678,Mobile Web,,Partial,Contact attempt,explanation,2000-01-01 03:04:05 UTC"]
      end,
    ])
    lines = csv |> String.split("\r\n") |> Enum.reject(fn x -> String.length(x) == 0 end)
    assert length(lines) == length(expected_list)
    assert lines == expected_list
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
