defmodule Ask.RespondentControllerTest do
  use Ask.ConnCase
  use Ask.TestHelpers
  use Ask.DummySteps

  alias Ask.{QuotaBucket, Survey, SurveyLogEntry, Response, Respondent, ShortLink, Stats, ActivityLog}


  @empty_stats %{
    "attempts" => nil,
    "total_call_time" => nil,
    "total_call_time_seconds" => nil,
    "total_received_sms" => 0,
    "total_sent_sms" => 0
  }

  describe "normal" do
    setup :user

    test "returns code 200 and empty list if there are no entries", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      conn = get conn, project_survey_respondent_path(conn, :index, project.id, survey.id)
      assert json_response(conn, 200)["data"]["respondents"] == []
      assert json_response(conn, 200)["meta"]["count"] == 0
    end

    test "fetches responses on index", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project)
      survey = insert(:survey, project: project, questionnaires: [questionnaire])
      respondent = insert(:respondent, survey: survey, mode: ["sms"], questionnaire_id: questionnaire.id, disposition: "completed")
      response = insert(:response, respondent: respondent, value: "Yes")
      response = Response |> Repo.get(response.id)
      respondent = Respondent |> Repo.get(respondent.id)
      conn = get conn, project_survey_respondent_path(conn, :index, project.id, survey.id)
      assert json_response(conn, 200)["data"]["respondents"] == [%{
                                                     "id" => respondent.id,
                                                     "phone_number" => respondent.hashed_number,
                                                     "survey_id" => survey.id,
                                                     "mode" => ["sms"],
                                                     "effective_modes" => nil,
                                                     "questionnaire_id" => questionnaire.id,
                                                     "disposition" => "completed",
                                                     "date" => DateTime.to_iso8601(response.updated_at),
                                                     "updated_at" => DateTime.to_iso8601(respondent.updated_at),
                                                     "responses" => [
                                                       %{
                                                         "value" => response.value,
                                                         "name" => response.field_name
                                                       }
                                                     ],
                                                     "stats" => @empty_stats
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

    test "lists stats for a given survey", %{conn: conn, user: user} do
      t = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 10, started_at: t, questionnaires: [questionnaire])
      insert_list(10, :respondent, survey: survey, questionnaire: questionnaire, disposition: "partial")
      insert(:respondent, survey: survey, disposition: "completed", questionnaire: questionnaire, updated_at: Ecto.DateTime.cast!("2016-01-01T10:00:00Z"))
      insert(:respondent, survey: survey, disposition: "completed", questionnaire: questionnaire, updated_at: Ecto.DateTime.cast!("2016-01-01T11:00:00Z"))
      insert_list(3, :respondent, survey: survey, disposition: "completed", questionnaire: questionnaire, updated_at: Ecto.DateTime.cast!("2016-01-02T10:00:00Z"))

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
            "registered" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "queued" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "failed" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
          },
        },
        "contacted" => %{
          "count" => 0,
          "percent" => 0.0,
          "detail" => %{
            "contacted" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "unresponsive" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
          },
        },
        "responsive" => %{
          "count" => 15,
          "percent" => 100.0,
          "detail" => %{
            "started" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "breakoff" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "partial" => %{"count" => 10, "percent" => 100*10/total, "by_reference" => %{string_questionnaire_id => 10}},
            "completed" => %{"count" => 5, "percent" => 100*5/total, "by_reference" => %{string_questionnaire_id => 5}},
            "ineligible" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "refused" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "rejected" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "interim partial" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0}
          },
        },
      }

      assert data["total_respondents"] == 15

      assert data["cumulative_percentages"] == %{
               to_string(questionnaire.id) => [
                 %{"date" => "2016-01-01", "percent" => 20.0},
                 %{"date" => "2016-01-02", "percent" => 50.0}
               ]
             }
    end

    test "respondents_by_disposition includes interim partial results", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      string_questionnaire_id = to_string(questionnaire.id)
      survey = insert(:survey, project: project, cutoff: 10, questionnaires: [questionnaire])
      insert_list(5, :respondent, survey: survey, questionnaire: questionnaire, disposition: "interim partial")

      conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)
      data = json_response(conn, 200)["data"]

      assert data["respondents_by_disposition"]["responsive"]["detail"]["interim partial"] == %{"count" => 5, "percent" => 100, "by_reference" => %{string_questionnaire_id => 5}}
    end

    test "cumulative percentages for a running survey with two questionnaires and two modes", %{conn: conn, user: user} do
      t = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
      project = create_project_for_user(user)
      q1 = insert(:questionnaire, name: "test 1", project: project, steps: @dummy_steps)
      q2 = insert(:questionnaire, name: "test 2", project: project, steps: @dummy_steps)
      survey =
        insert(
          :survey,
          project: project,
          questionnaires: [q1, q2],
          state: "running",
          cutoff: 10,
          mode: [["sms"], ["ivr"]],
          started_at: t,
          comparisons: [
            %{"ratio" => 25, "questionnaire_id" => q1.id, "mode" => ["sms"]},
            %{"ratio" => 25, "questionnaire_id" => q2.id, "mode" => ["sms"]},
            %{"ratio" => 25, "questionnaire_id" => q1.id, "mode" => ["ivr"]},
            %{"ratio" => 25, "questionnaire_id" => q2.id, "mode" => ["ivr"]},
          ]
        )

      insert(:respondent, survey: survey, disposition: "completed", questionnaire: q1, mode: ["sms"], updated_at: Ecto.DateTime.cast!("2016-01-01T10:00:00Z"))
      insert(:respondent, survey: survey, disposition: "completed", questionnaire: q2, mode: ["sms"], updated_at: Ecto.DateTime.cast!("2016-01-01T11:00:00Z"))
      insert_list(6,:respondent, survey: survey, disposition: "completed", questionnaire: q2, mode: ["ivr"], updated_at: Ecto.DateTime.cast!("2016-01-01T10:00:00Z"))
      insert_list(3, :respondent, survey: survey, disposition: "completed", questionnaire: q2, mode: ["ivr"], updated_at: Ecto.DateTime.cast!("2016-01-02T10:00:00Z"))

      conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)

      assert json_response(conn, 200)["data"]["cumulative_percentages"] == %{
               "#{q1.id}sms" => [
                 %{"date" => "2016-01-01", "percent" => 40.0},
                 %{
                   "date" => DateTime.utc_now() |> DateTime.to_date() |> Date.to_iso8601(),
                   "percent" => 40.0
                 }
               ],
               "#{q1.id}ivr" => [
                 %{"date" => "2016-01-01", "percent" => 0.0},
                 %{
                   "date" => DateTime.utc_now() |> DateTime.to_date() |> Date.to_iso8601(),
                   "percent" => 0.0
                 }
               ],
               "#{q2.id}ivr" => [%{"date" => "2016-01-01", "percent" => 100.0}],
               "#{q2.id}sms" => [
                 %{"date" => "2016-01-01", "percent" => 40.0},
                 %{
                   "date" => DateTime.utc_now() |> DateTime.to_date() |> Date.to_iso8601(),
                   "percent" => 40.0
                 }
               ]
             }
    end

    test "cumulative percentages for a completed survey with two questionnaires and two modes", %{conn: conn, user: user} do
      t = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
      project = create_project_for_user(user)
      q1 = insert(:questionnaire, name: "test 1", project: project, steps: @dummy_steps)
      q2 = insert(:questionnaire, name: "test 2", project: project, steps: @dummy_steps)
      survey =
        insert(
          :survey,
          project: project,
          questionnaires: [q1, q2],
          state: "terminated",
          cutoff: 10,
          mode: [["sms"], ["ivr"]],
          started_at: t,
          comparisons: [
            %{"ratio" => 25, "questionnaire_id" => q1.id, "mode" => ["sms"]},
            %{"ratio" => 25, "questionnaire_id" => q2.id, "mode" => ["sms"]},
            %{"ratio" => 25, "questionnaire_id" => q1.id, "mode" => ["ivr"]},
            %{"ratio" => 25, "questionnaire_id" => q2.id, "mode" => ["ivr"]},
          ]
        )

      insert(:respondent, survey: survey, disposition: "completed", questionnaire: q1, mode: ["sms"], updated_at: Ecto.DateTime.cast!("2016-01-01T10:00:00Z"))
      insert(:respondent, survey: survey, disposition: "completed", questionnaire: q2, mode: ["sms"], updated_at: Ecto.DateTime.cast!("2016-01-01T11:00:00Z"))
      insert_list(6,:respondent, survey: survey, disposition: "completed", questionnaire: q2, mode: ["ivr"], updated_at: Ecto.DateTime.cast!("2016-01-01T10:00:00Z"))
      insert_list(3, :respondent, survey: survey, disposition: "completed", questionnaire: q2, mode: ["ivr"], updated_at: Ecto.DateTime.cast!("2016-01-02T10:00:00Z"))

      conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)

      assert json_response(conn, 200)["data"]["cumulative_percentages"] == %{
               "#{q1.id}sms" => [%{"date" => "2016-01-01", "percent" => 40.0}],
               "#{q1.id}ivr" => [%{"date" => "2016-01-01", "percent" => 0.0}],
               "#{q2.id}sms" => [%{"date" => "2016-01-01", "percent" => 40.0}],
               "#{q2.id}ivr" => [%{"date" => "2016-01-01", "percent" => 100.0}]
             }
    end

    test "cumulative percentages for a survey with two modes", %{conn: conn, user: user} do
      t = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
      project = create_project_for_user(user)
      q1 = insert(:questionnaire, name: "test 1", project: project, steps: @dummy_steps)
      survey =
        insert(
          :survey,
          project: project,
          questionnaires: [q1],
          cutoff: 10,
          mode: [["sms"], ["ivr"]],
          started_at: t,
          comparisons: [
            %{"ratio" => 50, "questionnaire_id" => q1.id, "mode" => ["sms"]},
            %{"ratio" => 50, "questionnaire_id" => q1.id, "mode" => ["ivr"]},
          ]
        )

      insert_list(10, :respondent, survey: survey, questionnaire: q1, disposition: "partial")
      insert(:respondent, survey: survey, disposition: "completed", questionnaire: q1, mode: ["sms"], updated_at: Ecto.DateTime.cast!("2016-01-01T10:00:00Z"))
      insert(:respondent, survey: survey, disposition: "completed", questionnaire: q1, mode: ["sms"], updated_at: Ecto.DateTime.cast!("2016-01-02T11:00:00Z"))
      insert_list(30, :respondent, survey: survey, disposition: "completed", questionnaire: q1, mode: ["ivr"], updated_at: Ecto.DateTime.cast!("2016-01-01T10:00:00Z"))
      insert_list(30, :respondent, survey: survey, disposition: "completed", questionnaire: q1, mode: ["ivr"], updated_at: Ecto.DateTime.cast!("2016-01-02T10:00:00Z"))

      conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)

      assert json_response(conn, 200)["data"]["cumulative_percentages"] ==
               %{
                 "ivr" => [%{"date" => "2016-01-01", "percent" => 100.0}],
                 "sms" => [
                   %{"date" => "2016-01-01", "percent" => 20.0},
                   %{"date" => "2016-01-02", "percent" => 40.0}
                 ]
               }
    end

    test "stats do not crash when a respondent has 'completed' disposition but no 'completed_at'", %{conn: conn, user: user} do
      t = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 1, started_at: t, questionnaires: [questionnaire])
      insert(:respondent, survey: survey, disposition: "completed", questionnaire: questionnaire, updated_at: t |> Timex.to_erl |> Ecto.DateTime.from_erl)

      conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)

      assert json_response(conn, 200)["data"]["cumulative_percentages"] == %{
               to_string(questionnaire.id) => [%{"date" => "2016-01-01", "percent" => 100.0}]
             }
    end

    test "lists stats for a given survey with quotas", %{conn: conn, user: user} do
      t = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 10, started_at: t, quota_vars: ["gender"], questionnaires: [questionnaire])
      bucket_1 = insert(:quota_bucket, survey: survey, condition: %{gender: "male"}, quota: 4, count: 2)
      bucket_2 = insert(:quota_bucket, survey: survey, condition: %{gender: "female"}, quota: 12, count: 4)
      insert_list(10, :respondent, survey: survey, questionnaire: questionnaire, disposition: "partial")
      insert(:respondent, survey: survey, questionnaire: questionnaire, disposition: "completed", updated_at: Ecto.DateTime.cast!("2016-01-01T10:00:00Z"), quota_bucket: bucket_1)
      insert(:respondent, survey: survey, questionnaire: questionnaire, disposition: "completed", updated_at: Ecto.DateTime.cast!("2016-01-01T11:00:00Z"), quota_bucket: bucket_1)
      insert(:respondent, survey: survey, questionnaire: questionnaire, disposition: "rejected", updated_at: Ecto.DateTime.cast!("2016-01-02T10:00:00Z"), quota_bucket: bucket_2)
      insert_list(3, :respondent, survey: survey, questionnaire: questionnaire, disposition: "completed", updated_at: Ecto.DateTime.cast!("2016-01-02T10:00:00Z"), quota_bucket: bucket_2)

      conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)
      data = json_response(conn, 200)["data"]
      total = 16.0

      assert data["id"] == survey.id
      assert data["respondents_by_disposition"] == %{
        "uncontacted" => %{
          "count" => 0,
          "percent" => 0.0,
          "detail" => %{
            "registered" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "queued" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "failed" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
          },
        },
        "contacted" => %{
          "count" => 0,
          "percent" => 0.0,
          "detail" => %{
            "contacted" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "unresponsive" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
          },
        },
        "responsive" => %{
          "count" => 16,
          "percent" => 100.0,
          "detail" => %{
            "started" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "breakoff" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "partial" => %{"count" => 10, "percent" => 100*10/total, "by_reference" => %{"" => 10}},
            "completed" => %{"count" => 5, "percent" => 100*5/total, "by_reference" => %{"#{bucket_1.id}" => 2, "#{bucket_2.id}" => 3}},
            "ineligible" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "refused" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "rejected" => %{"count" => 1, "percent" => 100*1/total, "by_reference" => %{"#{bucket_2.id}" => 1}},
            "interim partial" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0}
          },
        },
      }

      assert data["total_respondents"] == 16
      assert data["cumulative_percentages"] ==
               %{
                 "#{bucket_1.id}" => [%{"date" => "2016-01-01", "percent" => 50.0}],
                 "#{bucket_2.id}" => [
                   %{"date" => "2016-01-01", "percent" => 0.0},
                   %{"date" => "2016-01-02", "percent" => 25.0}
                 ]
               }
    end

    test "respondents_by_disposition for a given survey with quotas includes interim partial results", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 10, quota_vars: ["gender"], questionnaires: [questionnaire])
      bucket_1 = insert(:quota_bucket, survey: survey, condition: %{gender: "male"}, quota: 4, count: 2)
      bucket_2 = insert(:quota_bucket, survey: survey, condition: %{gender: "female"}, quota: 12, count: 4)
      insert_list(2, :respondent, survey: survey, questionnaire: questionnaire, disposition: "interim partial", quota_bucket: bucket_1)
      insert_list(2, :respondent, survey: survey, questionnaire: questionnaire, disposition: "interim partial", quota_bucket: bucket_2)

      conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)
      data = json_response(conn, 200)["data"]

      assert data["respondents_by_disposition"]["responsive"]["detail"]["interim partial"] == %{"count" => 4, "percent" => 100, "by_reference" => %{ "#{bucket_1.id}" => 2, "#{bucket_2.id}" => 2}}
    end

    test "lists stats for a given survey, with dispositions", %{conn: conn, user: user} do
      t = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 10, started_at: t, questionnaires: [questionnaire], count_partial_results: true)
      insert_list(10, :respondent, survey: survey, state: "pending", disposition: "registered")
      insert(:respondent, survey: survey, state: "completed", questionnaire: questionnaire, disposition: "partial", updated_at: Ecto.DateTime.cast!("2016-01-01T10:00:00Z"))
      insert(:respondent, survey: survey, state: "completed", questionnaire: questionnaire, disposition: "completed", updated_at: Ecto.DateTime.cast!("2016-01-01T11:00:00Z"))
      insert_list(3, :respondent, survey: survey, state: "completed", questionnaire: questionnaire, disposition: "ineligible", updated_at: Ecto.DateTime.cast!("2016-01-02T10:00:00Z"))

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
            "registered" => %{"count" => 10, "percent" => 100*10/total, "by_reference" => %{"" => 10}},
            "queued" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "failed" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
          },
        },
        "contacted" => %{
          "count" => 0,
          "percent" => 0.0,
          "detail" => %{
            "contacted" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "unresponsive" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
          },
        },
        "responsive" => %{
          "count" => 5,
          "percent" => 100*5/total,
          "detail" => %{
            "started" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "breakoff" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "partial" => %{"count" => 1, "percent" => 100*1/total, "by_reference" => %{string_questionnaire_id => 1}},
            "completed" => %{"count" => 1, "percent" => 100*1/total, "by_reference" => %{string_questionnaire_id => 1}},
            "ineligible" => %{"count" => 3, "percent" => 100*3/total, "by_reference" => %{string_questionnaire_id => 3}},
            "refused" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "rejected" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            "interim partial" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0}
          },
        },
      }

      assert data["total_respondents"] == 15
      assert data["completion_percentage"] == 20

      assert data["cumulative_percentages"] == %{
               to_string(questionnaire.id) => [%{"date" => "2016-01-01", "percent" => 10.0}]
             }
    end

    test "fills previous dates when any respondent completed the survey with 0's", %{
      conn: conn,
      user: user
    } do
      t = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 10, started_at: t, questionnaires: [questionnaire])
      insert_list(10, :respondent, survey: survey, state: "pending")

      insert(
        :respondent,
        survey: survey,
        questionnaire: questionnaire,
        state: "completed",
        disposition: "completed",
        updated_at: Ecto.DateTime.cast!("2016-01-05T10:00:00Z")
      )

      conn = get(conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id))

      assert json_response(conn, 200)["data"]["cumulative_percentages"] == %{
               to_string(questionnaire.id) => [
                 %{"date" => "2016-01-01", "percent" => 0.0},
                 %{"date" => "2016-01-04", "percent" => 0.0},
                 %{"date" => "2016-01-05", "percent" => 10.0}
               ]
             }
    end

    test "fills dates with 0's if the survey is running and no respondent answered", %{
      conn: conn,
      user: user
    } do
      t = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 10, started_at: t, state: "running", questionnaires: [questionnaire])
      insert_list(10, :respondent, survey: survey, state: "pending")

      conn = get(conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id))

      assert json_response(conn, 200)["data"]["cumulative_percentages"] == %{
               to_string(questionnaire.id) => [
                 %{"date" => "2016-01-01", "percent" => 0.0},
                 %{
                   "date" => DateTime.utc_now() |> DateTime.to_date() |> Date.to_iso8601(),
                   "percent" => 0
                 }
               ]
             }
    end

    test "answers empty if anything breaks", %{conn: conn, user: user} do
      t = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 10, started_at: t, quota_vars: ["gender"], questionnaires: [questionnaire])
      bucket_1 = insert(:quota_bucket, survey: survey, condition: %{gender: "male"}, quota: 4, count: 2)
      bucket_2 = insert(:quota_bucket, survey: survey, condition: %{gender: "female"}, quota: 12, count: 4)
      bucket_3 = insert(:quota_bucket, survey: survey, condition: %{gender: "female"}, quota: 12, count: 4)
      insert_list(10, :respondent, survey: survey, questionnaire: questionnaire, disposition: "partial")
      insert(:respondent, survey: survey, questionnaire: questionnaire, disposition: "completed", updated_at: Ecto.DateTime.cast!("2016-01-01T10:00:00Z"), quota_bucket: bucket_1)
      insert(:respondent, survey: survey, questionnaire: questionnaire, disposition: "completed", updated_at: Ecto.DateTime.cast!("2016-01-01T11:00:00Z"), quota_bucket: bucket_1)
      insert(:respondent, survey: survey, questionnaire: questionnaire, disposition: "rejected", updated_at: Ecto.DateTime.cast!("2016-01-02T10:00:00Z"), quota_bucket: bucket_2)
      insert_list(3, :respondent, survey: survey, questionnaire: questionnaire, disposition: "completed", updated_at: Ecto.DateTime.cast!("2016-01-02T10:00:00Z"), quota_bucket: bucket_3)

      Repo.delete(bucket_3)

      conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)
      data = json_response(conn, 200)["data"]

      assert data["id"] == nil
      assert data["reference"] == %{}
      assert data["respondents_by_disposition"] == %{}
      assert data["cumulative_percentages"] == %{}
      assert data["completion_percentage"] == 0
      assert data["contacted_respondents"] == 0
      assert data["total_respondents"] == 0
      assert data["target"] == 0
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
              "registered" => %{"count" => 5, "percent" => 100*5/total, "by_reference" => %{"" => 5}},
              "queued" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
              "failed" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            },
          },
          "contacted" => %{
            "count" => 0,
            "percent" => 0.0,
            "detail" => %{
              "contacted" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
              "unresponsive" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
            },
          },
          "responsive" => %{
            "count" => 0,
            "percent" => 0.0,
            "detail" => %{
              "started" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
              "breakoff" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
              "partial" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
              "completed" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
              "ineligible" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
              "refused" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
              "rejected" => %{"count" => 0, "percent" => 0.0, "by_reference" => %{}},
              "interim partial" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0}
            },
          },
        },
        "cumulative_percentages" => %{},
        "total_respondents" => 5,
        "target" => 5,
        "contacted_respondents" => 0,
        "completion_percentage" => 0,
        "reference" => []
      }
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
      insert(:respondent, survey: survey, state: "active", disposition: "queued")

      conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)
      assert json_response(conn, 200) == %{ "data" => %{
        "reference" => [
         %{"name" => "Smokes: No - Exercises: No", "id" => qb1.id},
          %{"name" => "Smokes: No - Exercises: Yes", "id" => qb4.id}
        ],
        "completion_percentage" => 0.0,
        "contacted_respondents" => 0,
        "cumulative_percentages" => %{
          to_string(qb1.id) => [%{"date" => "2016-01-01", "percent" => 0.0}],
          to_string(qb4.id) => [%{"date" => "2016-01-01", "percent" => 0.0}]
        },
        "id" => survey.id,
        "respondents_by_disposition" => %{
          "contacted" => %{
            "count" => 0,
            "detail" => %{
              "contacted" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0},
              "unresponsive" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0}
            },
            "percent" => 0.0
          },
          "responsive" => %{
            "count" => 0,
            "detail" => %{
              "breakoff" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0},
              "completed" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0},
              "ineligible" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0},
              "partial" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0},
              "refused" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0},
              "rejected" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0},
              "started" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0},
              "interim partial" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0}
            },
            "percent" => 0.0
          },
          "uncontacted" => %{
            "count" => 4,
            "detail" => %{
              "failed" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0},
              "queued" => %{"by_reference" => %{"" => 1}, "count" => 1, "percent" => 25.0},
              "registered" => %{"by_reference" => %{"#{qb1.id}" => 1, "#{qb4.id}" => 2}, "count" => 3, "percent" => 75.0}
            },
            "percent" => 100.0
          }
        },
        "total_respondents" => 4,
        "target" => 5
      }}
    end

  test "quotas_stats with a zero or nil quota bucket", %{conn: conn, user: user} do
      t = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
      project = create_project_for_user(user)

      quotas = %{
        "vars" => ["Smokes", "Exercises"],
        "buckets" => [
          %{
            "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "No"}],
            "quota" => 0,
            "count" => 1
          },
          %{
            "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "Yes"}],
            "quota" => 5,
            "count" => 0
          },
          %{
            "condition" => [%{"store" => "Smokes", "value" => "yes"}, %{"store" => "Exercises", "value" => "No"}],
            "quota" => nil,
            "count" => 0
          },
          %{
            "condition" => [%{"store" => "Smokes", "value" => "Yes"}, %{"store" => "Exercises", "value" => "Yes"}],
            "quota" => 5,
            "count" => 2
          },
        ]
      }

      survey = insert(:survey, project: project, started_at: t)
      survey = survey
      |> Repo.preload([:quota_buckets])
      |> Survey.changeset(%{quotas: quotas})
      |> Repo.update!

      qb1 = (from q in QuotaBucket, where: q.condition == ^%{"Exercises" => "No", "Smokes" => "No"}) |> Repo.one
      qb2 = (from q in QuotaBucket, where: q.condition == ^%{"Exercises" => "Yes", "Smokes" => "No"}) |> Repo.one
      qb4 = (from q in QuotaBucket, where: q.condition == ^%{"Exercises" => "Yes", "Smokes" => "Yes"}) |> Repo.one

      insert(:respondent, survey: survey, state: "completed", disposition: "completed", quota_bucket_id: qb1.id, updated_at: Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}"))
      insert(:respondent, survey: survey, state: "completed", disposition: "completed", quota_bucket_id: qb4.id, updated_at: Timex.parse!("2016-01-01T11:00:00Z", "{ISO:Extended}"))
      insert(:respondent, survey: survey, state: "completed", disposition: "completed", quota_bucket_id: qb4.id, updated_at: Timex.parse!("2016-01-01T11:00:00Z", "{ISO:Extended}"))
      insert(:respondent, survey: survey, state: "active", disposition: "contacted", quota_bucket_id: qb4.id, updated_at: Timex.parse!("2016-01-01T11:00:00Z", "{ISO:Extended}"))
      insert(:respondent, survey: survey, state: "active", disposition: "queued")

      conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)
      assert json_response(conn, 200) == %{ "data" => %{
        "reference" => [
          %{"name" => "Smokes: No - Exercises: Yes", "id" => qb2.id},
          %{"name" => "Smokes: Yes - Exercises: Yes", "id" => qb4.id}
        ],
        "completion_percentage" => 30.0,
        "contacted_respondents" => 4,
        "cumulative_percentages" => %{
          to_string(qb2.id) => [%{"date" => "2016-01-01", "percent" => 0.0}],
          to_string(qb4.id) => [%{"date" => "2016-01-01", "percent" => 40.0}]
        },
        "id" => survey.id,
        "respondents_by_disposition" => %{
          "contacted" => %{
            "count" => 1,
            "detail" => %{
              "contacted" => %{"by_reference" => %{"#{qb4.id}" => 1}, "count" => 1, "percent" => 20.0},
              "unresponsive" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0}
            },
            "percent" => 20.0
          },
          "responsive" => %{
            "count" => 2,
            "detail" => %{
              "breakoff" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0},
              "completed" => %{"by_reference" => %{"#{qb4.id}"=> 2}, "count" => 2, "percent" => 40.0},
              "ineligible" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0},
              "partial" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0},
              "refused" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0},
              "rejected" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0},
              "started" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0},
              "interim partial" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0}
            },
            "percent" => 40.0
          },
          "uncontacted" => %{
            "count" => 1,
            "detail" => %{
              "failed" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0},
              "queued" => %{"by_reference" => %{"" => 1}, "count" => 1, "percent" => 20.0},
              "registered" => %{"by_reference" => %{}, "count" => 0, "percent" => 0.0}
            },
            "percent" => 20.0
          }
        },
        "total_respondents" => 5,
        "target" => 10
      }}
    end

    test "completion percentage considers partial and interim partial respondents when quotas are present and survey counts partial results", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, quota_vars: ["gender"], questionnaires: [questionnaire], count_partial_results: true)
      insert(:quota_bucket, survey: survey, condition: %{gender: "male"}, quota: 5, count: 2)
      insert(:quota_bucket, survey: survey, condition: %{gender: "female"}, quota: 5, count: 3)
      insert_list(2, :respondent, survey: survey, questionnaire: questionnaire, disposition: "partial")
      insert_list(2, :respondent, survey: survey, questionnaire: questionnaire, disposition: "interim partial")
      insert_list(1, :respondent, survey: survey, questionnaire: questionnaire, disposition: "completed")

      conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)
      data = json_response(conn, 200)["data"]

      assert data["completion_percentage"] == 50.0
    end

    test "completion percentage doesn't consider partial and interim partial respondents when quotas are present and survey doesn't count partial results", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, quota_vars: ["gender"], questionnaires: [questionnaire])
      insert(:quota_bucket, survey: survey, condition: %{gender: "male"}, quota: 5, count: 2)
      insert(:quota_bucket, survey: survey, condition: %{gender: "female"}, quota: 5, count: 3)
      insert_list(2, :respondent, survey: survey, questionnaire: questionnaire, disposition: "partial")
      insert_list(2, :respondent, survey: survey, questionnaire: questionnaire, disposition: "interim partial")
      insert_list(1, :respondent, survey: survey, questionnaire: questionnaire, disposition: "completed")

      conn = get conn, project_survey_respondents_stats_path(conn, :stats, project.id, survey.id)
      data = json_response(conn, 200)["data"]

      assert data["completion_percentage"] == 10.0
    end
  end

  describe "download" do
    setup :user

    test "download results csv", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule(), mode: [["sms", "ivr"], ["mobileweb"], ["sms", "mobileweb"]])
      group_1 = insert(:respondent_group)
      respondent_1 = insert(:respondent, survey: survey, hashed_number: "1asd12451eds", disposition: "partial", effective_modes: ["sms", "ivr"], respondent_group: group_1, stats: %Stats{total_received_sms: 4, total_sent_sms: 3, total_call_time_seconds: 12, attempts: %{sms: 1, mobileweb: 2, ivr: 3}})
      insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
      insert(:response, respondent: respondent_1, field_name: "Exercises", value: "No")
      insert(:response, respondent: respondent_1, field_name: "Perfect Number", value: "100")
      group_2 = insert(:respondent_group)
      respondent_2 = insert(:respondent, survey: survey, hashed_number: "34y5345tjyet", effective_modes: ["mobileweb"], respondent_group: group_2, stats: %Stats{total_sent_sms: 1})
      insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")

      conn = get conn, project_survey_respondents_results_path(conn, :results, survey.project.id, survey.id, %{"offset" => "0", "_format" => "csv"})
      csv = response(conn, 200)

      [line1, line2, line3, _] = csv |> String.split("\r\n")
      assert line1 == "respondent_id,date,modes,section_order,sample_file,Smokes,Exercises,Perfect_Number,Question,disposition,total_sent_sms,total_received_sms,sms_attempts,total_call_time,ivr_attempts,mobileweb_attempts"

      [line_2_hashed_number, _, line_2_modes, line_2_section_order, line_2_respondent_group, line_2_smoke, line_2_exercises, line_2_perfect_number, _, line_2_disp, line_2_total_sent_sms, line_2_total_received_sms, line_2_sms_attempts, line_2_total_call_time, line_2_ivr_attempts, line_2_mobileweb_attempts] = [line2] |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd

      assert line_2_hashed_number == respondent_1.hashed_number
      assert line_2_modes == "SMS, Phone call"
      assert line_2_respondent_group == group_1.name
      assert line_2_smoke == "Yes"
      assert line_2_exercises == "No"
      assert line_2_disp == "Partial"
      assert line_2_total_sent_sms == "3"
      assert line_2_total_received_sms == "4"
      assert line_2_total_call_time == "0m 12s"
      assert line_2_perfect_number == "100"
      assert line_2_section_order == ""
      assert line_2_sms_attempts == "1"
      assert line_2_mobileweb_attempts == "2"
      assert line_2_ivr_attempts == "3"

      [line_3_hashed_number, _, line_3_modes, line_3_section_order, line_3_respondent_group,line_3_smoke, line_3_exercises, _, _, line_3_disp, line_3_total_sent_sms, line_3_total_received_sms, line_3_sms_attempts, line_3_total_call_time, line_3_ivr_attempts, line_3_mobileweb_attempts] = [line3]  |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd
      assert line_3_hashed_number == respondent_2.hashed_number
      assert line_3_modes == "Mobile Web"
      assert line_3_respondent_group == group_2.name
      assert line_3_smoke == "No"
      assert line_3_exercises == ""
      assert line_3_disp == "Registered"
      assert line_3_total_sent_sms == "1"
      assert line_3_total_received_sms == "0"
      assert line_3_total_call_time == "0m 0s"
      assert line_3_section_order == ""
      assert line_3_sms_attempts == "0"
      assert line_3_mobileweb_attempts == "0"
      assert line_3_ivr_attempts == "0"
    end

    test "download results csv with sections", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @three_sections)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule(), mode: [["sms", "ivr"], ["mobileweb"], ["sms", "mobileweb"]])
      group_1 = insert(:respondent_group)
      respondent_1 = insert(:respondent, survey: survey, questionnaire: questionnaire, hashed_number: "1asd12451eds", disposition: "partial", effective_modes: ["sms", "ivr"], respondent_group: group_1, section_order: [0,1,2], stats: %Stats{total_received_sms: 4, total_sent_sms: 3, total_call_time: 12})
      insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
      insert(:response, respondent: respondent_1, field_name: "Refresh", value: "No")
      insert(:response, respondent: respondent_1, field_name: "Perfect_Number", value: "4")
      insert(:response, respondent: respondent_1, field_name: "Exercises", value: "No")
      group_2 = insert(:respondent_group)
      respondent_2 = insert(:respondent, survey: survey, questionnaire: questionnaire, hashed_number: "34y5345tjyet", effective_modes: ["mobileweb"], respondent_group: group_2, section_order: [2,1,0], stats: %Stats{total_sent_sms: 1})
      insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")

      conn = get conn, project_survey_respondents_results_path(conn, :results, survey.project.id, survey.id, %{"offset" => "0", "_format" => "csv"})
      csv = response(conn, 200)

      [line1, line2, line3, _] = csv |> String.split("\r\n")
      assert line1 == "respondent_id,date,modes,section_order,sample_file,Smokes,Exercises,Refresh,Probability,Last,Perfect_Number,Question,disposition,total_sent_sms,total_received_sms,sms_attempts,total_call_time,ivr_attempts,mobileweb_attempts"

      [line_2_hashed_number, _, line_2_modes, line_2_section_order, line_2_respondent_group, line_2_smoke, line_2_exercises, line_2_refresh, _, _, line_2_perfect_number, _, line_2_disp, line_2_total_sent_sms, line_2_total_received_sms, _, line_2_total_call_time, _, _] = [line2] |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd

      assert line_2_hashed_number == respondent_1.hashed_number
      assert line_2_modes == "SMS, Phone call"
      assert line_2_respondent_group == group_1.name
      assert line_2_smoke == "Yes"
      assert line_2_exercises == "No"
      assert line_2_perfect_number == "4"
      assert line_2_refresh == "No"
      assert line_2_disp == "Partial"
      assert line_2_total_sent_sms == "3"
      assert line_2_total_received_sms == "4"
      assert line_2_total_call_time == "12m 0s"
      assert line_2_section_order == "First section, Second section, Third section"

      [line_3_hashed_number, _, line_3_modes, line_3_section_order, line_3_respondent_group, line_3_smoke, line_3_exercises, line_3_refresh, _, _, _, _, line_3_disp, line_3_total_sent_sms, line_3_total_received_sms, _, line_3_total_call_time, _, _] = [line3]  |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd

      assert line_3_hashed_number == respondent_2.hashed_number
      assert line_3_modes == "Mobile Web"
      assert line_3_respondent_group == group_2.name
      assert line_3_smoke == "No"
      assert line_3_exercises == ""
      assert line_3_refresh == ""
      assert line_3_disp == "Registered"
      assert line_3_total_sent_sms == "1"
      assert line_3_total_received_sms == "0"
      assert line_3_total_call_time == "0m 0s"
      assert line_3_section_order == "Third section, Second section, First section"
    end

    test "download results csv with untitled sections", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @three_sections_untitled)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule(), mode: [["sms", "ivr"], ["mobileweb"], ["sms", "mobileweb"]])
      group_1 = insert(:respondent_group)
      respondent_1 = insert(:respondent, survey: survey, questionnaire: questionnaire, hashed_number: "1asd12451eds", disposition: "partial", effective_modes: ["sms", "ivr"], respondent_group: group_1, section_order: [0,1,2], stats: %Stats{total_received_sms: 4, total_sent_sms: 3, total_call_time: 12})
      group_2 = insert(:respondent_group)
      respondent_2 = insert(:respondent, survey: survey, questionnaire: questionnaire, hashed_number: "34y5345tjyet", effective_modes: ["mobileweb"], respondent_group: group_2, section_order: [2,1,0], stats: %Stats{total_sent_sms: 1})
      insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")

      conn = get conn, project_survey_respondents_results_path(conn, :results, survey.project.id, survey.id, %{"offset" => "0", "_format" => "csv"})
      csv = response(conn, 200)

      [line1, line2, line3, _] = csv |> String.split("\r\n")
      assert line1 == "respondent_id,date,modes,section_order,sample_file,Smokes,Exercises,Refresh,Probability,Last,Perfect_Number,Question,disposition,total_sent_sms,total_received_sms,sms_attempts,total_call_time,ivr_attempts,mobileweb_attempts"

      [line_2_hashed_number, _, _, line_2_section_order, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _] = [line2] |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd

      assert line_2_hashed_number == respondent_1.hashed_number
      assert line_2_section_order == "Untitled 1, Second section, Untitled 3"

      [line_3_hashed_number, _, _, line_3_section_order, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _] = [line3] |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd

      assert line_3_hashed_number == respondent_2.hashed_number
      assert line_3_section_order == "Untitled 3, Second section, Untitled 1"
    end

    test "download results csv with filter by disposition", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())
      group_1 = insert(:respondent_group)
      respondent_1 = insert(:respondent, survey: survey, hashed_number: "1asd12451eds", disposition: "partial", effective_modes: ["sms", "ivr"], respondent_group: group_1)
      insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
      insert(:response, respondent: respondent_1, field_name: "Exercises", value: "No")
      respondent_2 = insert(:respondent, survey: survey, hashed_number: "34y5345tjyet", effective_modes: ["mobileweb"])
      insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")

      conn = get conn, project_survey_respondents_results_path(conn, :results, survey.project.id, survey.id, %{"offset" => "0", "_format" => "csv", "disposition" => "registered"})
      csv = response(conn, 200)

      [line1, line2, _] = csv |> String.split("\r\n")
      assert line1 == "respondent_id,date,modes,section_order,sample_file,Smokes,Exercises,Perfect_Number,Question,disposition,total_sent_sms,total_received_sms,sms_attempts"

      [line_2_hashed_number, _, line_2_modes, _, line_2_respondent_group, line_2_smoke, line_2_exercises, _, _, line_2_disp, _, _, _] = [line2] |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd

      assert line_2_hashed_number == respondent_2.hashed_number
      assert line_2_modes == "Mobile Web"
      assert line_2_respondent_group == group_1.name
      assert line_2_smoke == "No"
      assert line_2_exercises == ""
      assert line_2_disp == "Registered"
    end

    test "download results csv with filter by update timestamp", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())
      group_1 = insert(:respondent_group)
      respondent_1 = insert(:respondent, survey: survey, hashed_number: "1asd12451eds", disposition: "partial", effective_modes: ["sms", "ivr"], respondent_group: group_1)
      insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
      insert(:response, respondent: respondent_1, field_name: "Exercises", value: "No")
      group_2 = insert(:respondent_group)
      respondent_2 = insert(:respondent, survey: survey, hashed_number: "34y5345tjyet", effective_modes: ["mobileweb"], respondent_group: group_2, updated_at: Timex.shift(Timex.now, hours: 2, minutes: 3))
      insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")

      conn = get conn, project_survey_respondents_results_path(conn, :results, survey.project.id, survey.id, %{"offset" => "0", "_format" => "csv", "since" => Timex.format!(Timex.shift(Timex.now, hours: 2), "%FT%T%:z", :strftime)})
      csv = response(conn, 200)

      [line1, line2, _] = csv |> String.split("\r\n")
      assert line1 == "respondent_id,date,modes,section_order,sample_file,Smokes,Exercises,Perfect_Number,Question,disposition,total_sent_sms,total_received_sms,sms_attempts"

      [line_2_hashed_number, _, line_2_modes, _, line_2_respondent_group, line_2_smoke, line_2_exercises, _, _, line_2_disp, _, _, _] = [line2] |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd

      assert line_2_hashed_number == respondent_2.hashed_number
      assert line_2_modes == "Mobile Web"
      assert line_2_respondent_group == group_1.name
      assert line_2_smoke == "No"
      assert line_2_exercises == ""
      assert line_2_disp == "Registered"
    end

    test "download results csv with filter by final state", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())
      group_1 = insert(:respondent_group)
      respondent_1 = insert(:respondent, survey: survey, hashed_number: "1asd12451eds", disposition: "partial", effective_modes: ["sms", "ivr"], respondent_group: group_1, state: "completed")
      insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
      insert(:response, respondent: respondent_1, field_name: "Exercises", value: "No")
      respondent_2 = insert(:respondent, survey: survey, hashed_number: "34y5345tjyet", effective_modes: ["mobileweb"])
      insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")

      conn = get conn, project_survey_respondents_results_path(conn, :results, survey.project.id, survey.id, %{"offset" => "0", "_format" => "csv", "final" => true})
      csv = response(conn, 200)

      [line1, line2, _] = csv |> String.split("\r\n")
      assert line1 == "respondent_id,date,modes,section_order,sample_file,Smokes,Exercises,Perfect_Number,Question,disposition,total_sent_sms,total_received_sms,sms_attempts"

      [line_2_hashed_number, _, line_2_modes, _, line_2_respondent_group, line_2_smoke, line_2_exercises, _, _, line_2_disp, _, _, _] = [line2] |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd

      assert line_2_hashed_number == respondent_1.hashed_number
      assert line_2_modes == "SMS, Phone call"
      assert line_2_respondent_group == group_1.name
      assert line_2_smoke == "Yes"
      assert line_2_exercises == "No"
      assert line_2_disp == "Partial"
    end

    test "download results csv with sample file column and two different respondent groups", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule(), mode: [["sms", "ivr"], ["mobileweb"], ["sms", "mobileweb"]])
      group_1 = insert(:respondent_group, name: "respondent_group_1_example.csv")
      respondent_1 = insert(:respondent, survey: survey, hashed_number: "1asd12451eds", disposition: "partial", effective_modes: ["sms", "ivr"], respondent_group: group_1, stats: %Stats{total_received_sms: 4, total_sent_sms: 3, total_call_time: 12})
      insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
      insert(:response, respondent: respondent_1, field_name: "Exercises", value: "No")
      group_2 = insert(:respondent_group, name: "respondent_group_2_example.csv")
      respondent_2 = insert(:respondent, survey: survey, hashed_number: "34y5345tjyet", effective_modes: ["mobileweb"], respondent_group: group_2, stats: %Stats{total_sent_sms: 1})
      insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")
      respondent_3 = insert(:respondent, survey: survey, hashed_number: "1hsd13451ftj", disposition: "partial", effective_modes: ["sms", "ivr"], respondent_group: group_1, stats: %Stats{total_received_sms: 4, total_sent_sms: 3, total_call_time: 12})
      insert(:response, respondent: respondent_3, field_name: "Smokes", value: "Yes")
      insert(:response, respondent: respondent_3, field_name: "Exercises", value: "No")
      respondent_4 = insert(:respondent, survey: survey, hashed_number: "67y5634tjsdfg", disposition: "partial", effective_modes: ["sms", "ivr"], respondent_group: group_2, stats: %Stats{total_received_sms: 4, total_sent_sms: 3, total_call_time: 12})
      insert(:response, respondent: respondent_4, field_name: "Smokes", value: "Yes")
      insert(:response, respondent: respondent_4, field_name: "Exercises", value: "No")

      conn = get conn, project_survey_respondents_results_path(conn, :results, survey.project.id, survey.id, %{"offset" => "0", "_format" => "csv"})
      csv = response(conn, 200)

      assert !String.contains?(group_1.name, [" ", ",", "*", ":","?", "\\", "|", "/", "<", ">"])
      assert !String.contains?(group_2.name, [" ", ",", "*", ":","?", "\\", "|", "/", "<", ">"])

      [line1, line2, line3, line4, line5, _] = csv |> String.split("\r\n")
      assert line1 == "respondent_id,date,modes,section_order,sample_file,Smokes,Exercises,Perfect_Number,Question,disposition,total_sent_sms,total_received_sms,sms_attempts,total_call_time,ivr_attempts,mobileweb_attempts"

      [line_2_hashed_number, _, line_2_modes, _, line_2_respondent_group, _, _, _, _, _, _, _, _, _, _, _] = [line2] |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd

      assert line_2_hashed_number == respondent_1.hashed_number
      assert line_2_modes == "SMS, Phone call"
      assert line_2_respondent_group == group_1.name

      [line_3_hashed_number, _, line_3_modes, _, line_3_respondent_group,_, _, _, _, _, _, _, _, _, _, _] = [line3]  |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd
      assert line_3_hashed_number == respondent_2.hashed_number
      assert line_3_modes == "Mobile Web"
      assert line_3_respondent_group == group_2.name

      [line_4_hashed_number, _, line_4_modes, _, line_4_respondent_group,_, _, _, _, _, _, _, _, _, _, _] = [line4]  |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd
      assert line_4_hashed_number == respondent_3.hashed_number
      assert line_4_modes == "SMS, Phone call"
      assert line_4_respondent_group == group_1.name

      [line_5_hashed_number, _, line_5_modes, _, line_5_respondent_group,_, _, _, _, _, _, _, _, _, _, _] = [line5]  |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd
      assert line_5_hashed_number == respondent_4.hashed_number
      assert line_5_modes == "SMS, Phone call"
      assert line_5_respondent_group == group_2.name

    end

    test "download results json", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())
      respondent_1 = insert(:respondent, survey: survey, hashed_number: "1asd12451eds", disposition: "partial", effective_modes: ["sms", "ivr"], questionnaire_id: questionnaire.id)
      respondent_1 = Repo.get(Respondent, respondent_1.id)
      insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
      response_1 = insert(:response, respondent: respondent_1, field_name: "Exercises", value: "No")
      response_1 = Repo.get(Response, response_1.id)
      respondent_2 = insert(:respondent, survey: survey, hashed_number: "34y5345tjyet", effective_modes: ["mobileweb"], questionnaire_id: questionnaire.id)
      respondent_2 = Repo.get(Respondent, respondent_2.id)
      response_2 = insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")
      response_2 = Repo.get(Response, response_2.id)

      conn = get conn, project_survey_respondents_results_path(conn, :results, survey.project.id, survey.id, %{"offset" => "0", "_format" => "json"})
      assert json_response(conn, 200)["data"]["respondents"] == [
        %{
          "id" => respondent_1.id,
          "phone_number" => respondent_1.hashed_number,
          "survey_id" => survey.id,
          "mode" => nil,
          "effective_modes" => ["sms", "ivr"],
          "questionnaire_id" => questionnaire.id,
          "disposition" => "partial",
          "date" => DateTime.to_iso8601(response_1.updated_at),
          "updated_at" => DateTime.to_iso8601(respondent_1.updated_at),
          "responses" => [
            %{
              "value" => "Yes",
              "name" => "Smokes"
            },
            %{
              "value" => "No",
              "name" => "Exercises"
            }
          ],
          "stats" => @empty_stats
        },
        %{
          "id" => respondent_2.id,
          "phone_number" => respondent_2.hashed_number,
          "survey_id" => survey.id,
          "mode" => nil,
          "effective_modes" => ["mobileweb"],
          "questionnaire_id" => questionnaire.id,
          "disposition" => "registered",
          "date" => DateTime.to_iso8601(response_2.updated_at),
          "updated_at" => DateTime.to_iso8601(respondent_2.updated_at),
          "responses" => [
            %{
              "value" => "No",
              "name" => "Smokes"
            }
          ],
          "stats" => @empty_stats
        }
      ]
    end

    test "download results json with filter by disposition", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())
      respondent_1 = insert(:respondent, survey: survey, hashed_number: "1asd12451eds", disposition: "partial", effective_modes: ["sms", "ivr"], questionnaire_id: questionnaire.id)
      respondent_1 = Repo.get(Respondent, respondent_1.id)
      insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
      response_1 = insert(:response, respondent: respondent_1, field_name: "Exercises", value: "No")
      response_1 = Repo.get(Response, response_1.id)
      respondent_2 = insert(:respondent, survey: survey, hashed_number: "34y5345tjyet", effective_modes: ["mobileweb"], questionnaire_id: questionnaire.id)
      respondent_2 = Repo.get(Respondent, respondent_2.id)
      insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")

      conn = get conn, project_survey_respondents_results_path(conn, :results, survey.project.id, survey.id, %{"offset" => "0", "_format" => "json", "disposition" => "partial"})
      assert json_response(conn, 200)["data"]["respondents"] == [
        %{
           "id" => respondent_1.id,
           "phone_number" => respondent_1.hashed_number,
           "survey_id" => survey.id,
           "mode" => nil,
           "effective_modes" => ["sms", "ivr"],
           "questionnaire_id" => questionnaire.id,
           "disposition" => "partial",
           "date" => DateTime.to_iso8601(response_1.updated_at),
           "updated_at" => DateTime.to_iso8601(respondent_1.updated_at),
           "responses" => [
             %{
               "value" => "Yes",
               "name" => "Smokes"
             },
             %{
               "value" => "No",
               "name" => "Exercises"
             }
           ],
           "stats" => @empty_stats
        }
      ]
    end

    test "download results json with filter by update timestamp", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())
      respondent_1 = insert(:respondent, survey: survey, hashed_number: "1asd12451eds", disposition: "partial", effective_modes: ["sms", "ivr"], questionnaire_id: questionnaire.id)
      insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
      insert(:response, respondent: respondent_1, field_name: "Exercises", value: "No")
      respondent_2 = insert(:respondent, survey: survey, hashed_number: "34y5345tjyet", effective_modes: ["mobileweb"], questionnaire_id: questionnaire.id, updated_at: Timex.shift(Timex.now, hours: 2, minutes: 3))
      respondent_2 = Repo.get(Respondent, respondent_2.id)
      response_2 = insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")
      response_2 = Repo.get(Response, response_2.id)

      conn = get conn, project_survey_respondents_results_path(conn, :results, survey.project.id, survey.id, %{"offset" => "0", "_format" => "json", "since" => Timex.format!(Timex.shift(Timex.now, hours: 2), "%FT%T%:z", :strftime)})
      assert json_response(conn, 200)["data"]["respondents"] == [
        %{
           "id" => respondent_2.id,
           "phone_number" => respondent_2.hashed_number,
           "survey_id" => survey.id,
           "mode" => nil,
           "effective_modes" => ["mobileweb"],
           "questionnaire_id" => questionnaire.id,
           "disposition" => "registered",
           "date" => DateTime.to_iso8601(response_2.updated_at),
           "updated_at" => DateTime.to_iso8601(respondent_2.updated_at),
           "responses" => [
             %{
               "value" => "No",
               "name" => "Smokes"
             }
           ],
           "stats" => @empty_stats
        }
      ]
    end

    test "download results json with filter by final state", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())
      respondent_1 = insert(:respondent, survey: survey, hashed_number: "1asd12451eds", disposition: "partial", effective_modes: ["sms", "ivr"], questionnaire_id: questionnaire.id)
      insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
      insert(:response, respondent: respondent_1, field_name: "Exercises", value: "No")
      respondent_2 = insert(:respondent, survey: survey, hashed_number: "34y5345tjyet", effective_modes: ["mobileweb"], questionnaire_id: questionnaire.id, state: "completed")
      respondent_2 = Repo.get(Respondent, respondent_2.id)
      response_2 = insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")
      response_2 = Repo.get(Response, response_2.id)

      conn = get conn, project_survey_respondents_results_path(conn, :results, survey.project.id, survey.id, %{"offset" => "0", "_format" => "json", "final" => true})
      assert json_response(conn, 200)["data"]["respondents"] == [
        %{
           "id" => respondent_2.id,
           "phone_number" => respondent_2.hashed_number,
           "survey_id" => survey.id,
           "mode" => nil,
           "effective_modes" => ["mobileweb"],
           "questionnaire_id" => questionnaire.id,
           "disposition" => "registered",
           "date" => DateTime.to_iso8601(response_2.updated_at),
           "updated_at" => DateTime.to_iso8601(respondent_2.updated_at),
           "responses" => [
             %{
               "value" => "No",
               "name" => "Smokes"
             }
           ],
           "stats" => @empty_stats
        }
      ]
    end

    test "download results csv with comparisons", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      questionnaire2 = insert(:questionnaire, name: "test 2", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire, questionnaire2], state: "ready", schedule: completed_schedule(),
        comparisons: [
          %{"mode" => ["sms"], "questionnaire_id" => questionnaire.id, "ratio" => 50},
          %{"mode" => ["sms"], "questionnaire_id" => questionnaire2.id, "ratio" => 50},
        ]
      )
      group_1 = insert(:respondent_group)
      respondent_1 = insert(:respondent, survey: survey, questionnaire_id: questionnaire.id, mode: ["sms"], respondent_group: group_1, disposition: "partial", stats: %Stats{attempts: %{sms: 2}})
      insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
      insert(:response, respondent: respondent_1, field_name: "Perfect_Number", value: "No")
      respondent_2 = insert(:respondent, survey: survey, questionnaire_id: questionnaire2.id, mode: ["sms", "ivr"], respondent_group: group_1, disposition: "completed", stats: %Stats{attempts: %{sms: 5}})
      insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")

      conn = get conn, project_survey_respondents_results_path(conn, :results, survey.project.id, survey.id, %{"offset" => "0", "_format" => "csv"})
      csv = response(conn, 200)

      [line1, line2, line3, _] = csv |> String.split("\r\n")
      assert line1 == "respondent_id,date,modes,section_order,sample_file,Smokes,Exercises,Perfect_Number,Question,variant,disposition,total_sent_sms,total_received_sms,sms_attempts"

      [line_2_hashed_number, _, _, _, _,line_2_smoke, _, line_2_number, _, line_2_variant, line_2_disp, _, _, line_2_sms_attempts] = [line2] |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd
      assert line_2_hashed_number == respondent_1.hashed_number |> to_string
      assert line_2_smoke == "Yes"
      assert line_2_number == "No"
      assert line_2_variant == "test - SMS"
      assert line_2_disp == "Partial"
      assert line_2_sms_attempts == "2"

      [line_3_hashed_number, _, _, _, _,line_3_smoke, _, line_3_number, _, line_3_variant, line_3_disp, _, _, line_3_sms_attempts] = [line3] |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd
      assert line_3_hashed_number == respondent_2.hashed_number |> to_string
      assert line_3_smoke == "No"
      assert line_3_number == ""
      assert line_3_variant == "test 2 - SMS with phone call fallback"
      assert line_3_disp == "Completed"
      assert line_3_sms_attempts == "5"
    end

    test "download results json with comparisons", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      questionnaire2 = insert(:questionnaire, name: "test 2", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire, questionnaire2], state: "ready", schedule: completed_schedule(),
        comparisons: [
          %{"mode" => ["sms"], "questionnaire_id" => questionnaire.id, "ratio" => 50},
          %{"mode" => ["sms"], "questionnaire_id" => questionnaire2.id, "ratio" => 50},
        ]
      )

      respondent_1 = insert(:respondent, survey: survey, hashed_number: "1asd12451eds", disposition: "partial", effective_modes: ["sms", "ivr"], mode: ["sms"], questionnaire_id: questionnaire.id)
      respondent_1 = Repo.get(Respondent, respondent_1.id)
      insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
      response_1 = insert(:response, respondent: respondent_1, field_name: "Perfect Number", value: "No")
      response_1 = Repo.get(Response, response_1.id)

      respondent_2 = insert(:respondent, survey: survey, hashed_number: "34y5345tjyet", effective_modes: ["mobileweb"], mode: ["sms", "ivr"], questionnaire_id: questionnaire2.id, disposition: "completed")
      respondent_2 = Repo.get(Respondent, respondent_2.id)
      response_2 = insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")
      response_2 = Repo.get(Response, response_2.id)

      conn = get conn, project_survey_respondents_results_path(conn, :results, survey.project.id, survey.id, %{"offset" => "0", "_format" => "json"})
      assert json_response(conn, 200)["data"]["respondents"] == [
        %{
           "id" => respondent_1.id,
           "phone_number" => respondent_1.hashed_number,
           "survey_id" => survey.id,
           "mode" => ["sms"],
           "effective_modes" =>["sms", "ivr"],
           "questionnaire_id" => questionnaire.id,
           "disposition" => "partial",
           "date" => DateTime.to_iso8601(response_1.updated_at),
           "updated_at" => DateTime.to_iso8601(respondent_1.updated_at),
           "experiment_name" => "test - SMS",
           "responses" => [
             %{
               "value" => "Yes",
               "name" => "Smokes"
             },
             %{
               "value" => "No",
               "name" => "Perfect Number"
             }
           ],
          "stats" => @empty_stats
        },
        %{
           "id" => respondent_2.id,
           "phone_number" => respondent_2.hashed_number,
           "survey_id" => survey.id,
           "mode" => ["sms", "ivr"],
           "effective_modes" =>["mobileweb"],
           "questionnaire_id" => questionnaire2.id,
           "experiment_name" => "test 2 - SMS with phone call fallback",
           "disposition" => "completed",
           "date" => DateTime.to_iso8601(response_2.updated_at),
           "updated_at" => DateTime.to_iso8601(respondent_2.updated_at),
           "responses" => [
             %{
               "value" => "No",
               "name" => "Smokes"
             }
           ],
          "stats" => @empty_stats
        }
      ]
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
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())
      group_1 = insert(:respondent_group)
      respondent_1 = insert(:respondent, survey: survey, hashed_number: "1asd12451eds", disposition: "partial", respondent_group: group_1)
      insert(:response, respondent: respondent_1, field_name: "language", value: "es")

      conn = get conn, project_survey_respondents_results_path(conn, :results, survey.project.id, survey.id, %{"offset" => "0", "_format" => "csv"})
      csv = response(conn, 200)

      [line1, line2, _] = csv |> String.split("\r\n")
      assert line1 == "respondent_id,date,modes,section_order,sample_file,language,disposition,total_sent_sms,total_received_sms,sms_attempts"

      [line_2_hashed_number, _, _, _, _,line_2_language, _, _, _, _] = [line2] |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd
      assert line_2_hashed_number == respondent_1.hashed_number
      assert line_2_language == "español"
    end

    test "download disposition history csv", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())
      respondent_1 = insert(:respondent, survey: survey, hashed_number: "1asd12451eds", disposition: "partial")
      respondent_2 = insert(:respondent, survey: survey, hashed_number: "34y5345tjyet")

      insert(:respondent_disposition_history, survey: survey, respondent: respondent_1, respondent_hashed_number: respondent_1.hashed_number, disposition: "partial", mode: "sms", inserted_at: Ecto.DateTime.cast!("2000-01-01 01:02:03"))
      insert(:respondent_disposition_history, survey: survey, respondent: respondent_1, respondent_hashed_number: respondent_1.hashed_number, disposition: "completed",  mode: "sms",inserted_at: Ecto.DateTime.cast!("2000-01-01 02:03:04"))

      insert(:respondent_disposition_history, survey: survey, respondent: respondent_2, respondent_hashed_number: respondent_2.hashed_number, disposition: "partial", mode: "ivr", inserted_at: Ecto.DateTime.cast!("2000-01-01 03:04:05"))
      insert(:respondent_disposition_history, survey: survey, respondent: respondent_2, respondent_hashed_number: respondent_2.hashed_number, disposition: "completed", mode: "ivr", inserted_at: Ecto.DateTime.cast!("2000-01-01 04:05:06"))

      conn = get conn, project_survey_respondents_disposition_history_path(conn, :disposition_history, survey.project.id, survey.id, %{"_format" => "csv"})
      csv = response(conn, 200)

      lines = csv |> String.split("\r\n") |> Enum.reject(fn x -> String.length(x) == 0 end)
      assert lines == ["Respondent ID,Disposition,Mode,Timestamp",
       "1asd12451eds,partial,SMS,2000-01-01 01:02:03 UTC",
       "1asd12451eds,completed,SMS,2000-01-01 02:03:04 UTC",
       "34y5345tjyet,partial,Phone call,2000-01-01 03:04:05 UTC",
       "34y5345tjyet,completed,Phone call,2000-01-01 04:05:06 UTC"]
    end

    test "download incentives", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())
      completed_at = Ecto.DateTime.cast!("2019-11-10 09:00:00")
      insert(:respondent, survey: survey, phone_number: "1234", disposition: "partial", questionnaire_id: questionnaire.id, mode: ["sms"])
      insert(:respondent, survey: survey, phone_number: "5678", disposition: "completed", questionnaire_id: questionnaire.id, mode: ["sms", "ivr"], completed_at: completed_at)
      insert(:respondent, survey: survey, phone_number: "9012", disposition: "completed", mode: ["sms", "ivr"])
      insert(:respondent, survey: survey, phone_number: "4321", disposition: "completed", questionnaire_id: questionnaire.id, mode: ["ivr"])

      conn = get conn, project_survey_respondents_incentives_path(conn, :incentives, survey.project.id, survey.id, %{"_format" => "csv"})
      csv = response(conn, 200)

      lines = csv |> String.split("\r\n") |> Enum.reject(fn x -> String.length(x) == 0 end)
      assert lines == [
        "Telephone number,Questionnaire-Mode,Completion date",
        "5678,test - SMS with phone call fallback,\"Nov 10, 2019 UTC\"",
        "4321,test - Phone call,"
      ]
    end

    test "download interactions", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())
      respondent_1 = insert(:respondent, survey: survey, hashed_number: "1234")
      respondent_2 = insert(:respondent, survey: survey, hashed_number: "5678")
      channel = insert(:channel, name: "test_channel")
      for _ <- 1..200 do
        insert(:survey_log_entry, survey: survey, mode: "sms",respondent: respondent_2, respondent_hashed_number: "5678", channel: channel, disposition: "completed", action_type: "prompt", action_data: "explanation", timestamp: Ecto.DateTime.cast!("2000-01-01 01:02:03"))
        insert(:survey_log_entry, survey: survey, mode: "ivr",respondent: respondent_1, respondent_hashed_number: "1234", channel: nil, disposition: "partial", action_type: "contact", action_data: "explanation", timestamp: Ecto.DateTime.cast!("2000-01-01 02:03:04"))
        insert(:survey_log_entry, survey: survey, mode: "mobileweb",respondent: respondent_2, respondent_hashed_number: "5678", channel: nil, disposition: "partial", action_type: "contact", action_data: "explanation", timestamp: Ecto.DateTime.cast!("2000-01-01 03:04:05"))
      end

      conn = get conn, project_survey_respondents_interactions_path(conn, :interactions, survey.project.id, survey.id, %{"_format" => "csv"})
      csv = response(conn, 200)

      respondent_1_interactions_ids = Repo.all(
        from entry in SurveyLogEntry,
          join: r in Respondent, on: entry.respondent_id == r.id,
          where: r.id == ^respondent_1.id,
          order_by: entry.id,
          select: entry.id
      )

      respondent_2_interactions_ids = Repo.all(
        from entry in SurveyLogEntry,
          join: r in Respondent, on: entry.respondent_id == r.id,
          where: r.id == ^respondent_2.id,
          order_by: entry.id,
          select: entry.id
      )

      expected_list = List.flatten(
        ["ID,Respondent ID,Mode,Channel,Disposition,Action Type,Action Data,Timestamp",
        for i <- 0..199 do
          interaction_id = respondent_1_interactions_ids |> Enum.at(i)
          "#{interaction_id},1234,IVR,,Partial,Contact attempt,explanation,2000-01-01 02:03:04 UTC"
        end,
        for i <- 0..199 do
          interaction_id_sms = respondent_2_interactions_ids |> Enum.at(2*i)
          interaction_id_web = respondent_2_interactions_ids |> Enum.at(2*i+1)
          ["#{interaction_id_sms},5678,SMS,test_channel,Completed,Prompt,explanation,2000-01-01 01:02:03 UTC",
          "#{interaction_id_web},5678,Mobile Web,,Partial,Contact attempt,explanation,2000-01-01 03:04:05 UTC"]
        end,
      ])
      lines = csv |> String.split("\r\n") |> Enum.reject(fn x -> String.length(x) == 0 end)
      assert length(lines) == length(expected_list)
      assert lines == expected_list
    end
  end

  describe "links" do
    setup :user

    test "download results csv using a download link", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())
      group_1 = insert(:respondent_group)
      respondent_1 = insert(:respondent, survey: survey, hashed_number: "1asd12451eds", disposition: "partial", effective_modes: ["sms", "ivr"], respondent_group: group_1)
      insert(:response, respondent: respondent_1, field_name: "Smokes", value: "Yes")
      insert(:response, respondent: respondent_1, field_name: "Exercises", value: "No")
      respondent_2 = insert(:respondent, survey: survey, hashed_number: "34y5345tjyet", effective_modes: ["mobileweb"], respondent_group: group_1)
      insert(:response, respondent: respondent_2, field_name: "Smokes", value: "No")

      {:ok, link} = ShortLink.generate_link(Survey.link_name(survey, :results), project_survey_respondents_results_path(conn, :results, project, survey, %{"_format" => "csv"}))

      conn = get conn, short_link_path(conn, :access, link.hash)
      # conn = get conn, project_survey_respondents_results_path(conn, :results, survey.project.id, survey.id, %{"offset" => "0", "_format" => "csv"})
      csv = response(conn, 200)

      [line1, line2, line3, _] = csv |> String.split("\r\n")
      assert line1 == "respondent_id,date,modes,section_order,sample_file,Smokes,Exercises,Perfect_Number,Question,disposition,total_sent_sms,total_received_sms,sms_attempts"

      [line_2_hashed_number, _, line_2_modes, _, line_2_respondent_group, line_2_smoke, line_2_exercises, _, _, line_2_disp, _, _, _] = [line2] |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd

      assert line_2_hashed_number == respondent_1.hashed_number
      assert line_2_modes == "SMS, Phone call"
      assert line_2_respondent_group == group_1.name
      assert line_2_smoke == "Yes"
      assert line_2_exercises == "No"
      assert line_2_disp == "Partial"

      [line_3_hashed_number, _, line_3_modes, _, line_3_respondent_group, line_3_smoke, line_3_exercises, _, _, line_3_disp, _, _, _] = [line3]  |> Stream.map(&(&1)) |> CSV.decode |> Enum.to_list |> hd
      assert line_3_hashed_number == respondent_2.hashed_number
      assert line_3_modes == "Mobile Web"
      assert line_3_respondent_group == group_1.name
      assert line_3_smoke == "No"
      assert line_3_exercises == ""
      assert line_3_disp == "Registered"
    end

    test "generates log when downloading results csv", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule(), mode: [["sms", "ivr"], ["mobileweb"], ["sms", "mobileweb"]])

      remote_ip = {192, 168, 0, 128}
      remote_ip_string = "192.168.0.128"
      conn = conn |> Map.put(:remote_ip, remote_ip)

      {:ok, link} = ShortLink.generate_link(Survey.link_name(survey, :results), project_survey_respondents_results_path(conn, :results, project, survey, %{"_format" => "csv"}))
      get conn, short_link_path(conn, :access, link.hash)

      assert_download_log(%{log: ActivityLog |> Repo.one,
        user: user,
        project: project,
        survey: survey,
        report_type: "survey_results",
        remote_ip: remote_ip_string
      })
    end

    test "download disposition history using download link", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())
      respondent_1 = insert(:respondent, survey: survey, hashed_number: "1asd12451eds", disposition: "partial")
      respondent_2 = insert(:respondent, survey: survey, hashed_number: "34y5345tjyet")

      insert(:respondent_disposition_history, survey: survey, respondent: respondent_1, respondent_hashed_number: respondent_1.hashed_number, disposition: "partial", mode: "sms", inserted_at: Ecto.DateTime.cast!("2000-01-01 01:02:03"))
      insert(:respondent_disposition_history, survey: survey, respondent: respondent_1, respondent_hashed_number: respondent_1.hashed_number, disposition: "completed",  mode: "sms",inserted_at: Ecto.DateTime.cast!("2000-01-01 02:03:04"))

      insert(:respondent_disposition_history, survey: survey, respondent: respondent_2, respondent_hashed_number: respondent_2.hashed_number, disposition: "partial", mode: "ivr", inserted_at: Ecto.DateTime.cast!("2000-01-01 03:04:05"))
      insert(:respondent_disposition_history, survey: survey, respondent: respondent_2, respondent_hashed_number: respondent_2.hashed_number, disposition: "completed", mode: "ivr", inserted_at: Ecto.DateTime.cast!("2000-01-01 04:05:06"))

      {:ok, link} = ShortLink.generate_link(Survey.link_name(survey, :results), project_survey_respondents_disposition_history_path(conn, :disposition_history, project, survey, %{"_format" => "csv"}))

      conn = get conn, short_link_path(conn, :access, link.hash)
      # conn = get conn, project_survey_respondents_disposition_history_path(conn, :disposition_history, survey.project.id, survey.id, %{"_format" => "csv"})
      csv = response(conn, 200)

      lines = csv |> String.split("\r\n") |> Enum.reject(fn x -> String.length(x) == 0 end)
      assert lines == ["Respondent ID,Disposition,Mode,Timestamp",
       "1asd12451eds,partial,SMS,2000-01-01 01:02:03 UTC",
       "1asd12451eds,completed,SMS,2000-01-01 02:03:04 UTC",
       "34y5345tjyet,partial,Phone call,2000-01-01 03:04:05 UTC",
       "34y5345tjyet,completed,Phone call,2000-01-01 04:05:06 UTC"]
    end

    test "generates log when downloading disposition_history csv", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule(), mode: [["sms", "ivr"], ["mobileweb"], ["sms", "mobileweb"]])

      remote_ip = {192, 168, 0, 128}
      remote_ip_string = "192.168.0.128"
      conn = conn |> Map.put(:remote_ip, remote_ip)

      {:ok, link} = ShortLink.generate_link(Survey.link_name(survey, :disposition_history), project_survey_respondents_disposition_history_path(conn, :disposition_history, project, survey, %{"_format" => "csv"}))
      get conn, short_link_path(conn, :access, link.hash)

      assert_download_log(%{log: ActivityLog |> Repo.one,
        user: user,
        project: project,
        survey: survey,
        report_type: "disposition_history",
        remote_ip: remote_ip_string
      })
    end

    test "download incentives using download link", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())
      completed_at = Ecto.DateTime.cast!("2019-11-15 19:00:00")
      insert(:respondent, survey: survey, phone_number: "1234", disposition: "partial", questionnaire_id: questionnaire.id, mode: ["sms"])
      insert(:respondent, survey: survey, phone_number: "5678", disposition: "completed", questionnaire_id: questionnaire.id, mode: ["sms", "ivr"], completed_at: completed_at)
      insert(:respondent, survey: survey, phone_number: "9012", disposition: "completed", mode: ["sms", "ivr"])

      {:ok, link} = ShortLink.generate_link(Survey.link_name(survey, :results), project_survey_respondents_incentives_path(conn, :incentives, project, survey, %{"_format" => "csv"}))

      conn = get conn, short_link_path(conn, :access, link.hash)
      # conn = get conn, project_survey_respondents_incentives_path(conn, :incentives, survey.project.id, survey.id, %{"_format" => "csv"})
      csv = response(conn, 200)

      lines = csv |> String.split("\r\n") |> Enum.reject(fn x -> String.length(x) == 0 end)
      assert lines == [
        "Telephone number,Questionnaire-Mode,Completion date",
        "5678,test - SMS with phone call fallback,\"Nov 15, 2019 UTC\""
      ]
    end

    test "generates log when downloading incentives csv", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())

      remote_ip = {192, 168, 0, 128}
      remote_ip_string = "192.168.0.128"
      conn = conn |> Map.put(:remote_ip, remote_ip)

      {:ok, link} = ShortLink.generate_link(Survey.link_name(survey, :incentives), project_survey_respondents_incentives_path(conn, :incentives, project, survey, %{"_format" => "csv"}))
      get conn, short_link_path(conn, :access, link.hash)

      assert_download_log(%{log: ActivityLog |> Repo.one,
        user: user,
        project: project,
        survey: survey,
        report_type: "incentives",
        remote_ip: remote_ip_string
      })
    end

    test "download interactions using download link", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())
      respondent_1 = insert(:respondent, survey: survey, hashed_number: "1234")
      respondent_2 = insert(:respondent, survey: survey, hashed_number: "5678")
      channel = insert(:channel, name: "test_channel")
      for _ <- 1..200 do
        insert(:survey_log_entry, survey: survey, mode: "sms",respondent: respondent_2, respondent_hashed_number: "5678", channel: channel, disposition: "completed", action_type: "prompt", action_data: "explanation", timestamp: Ecto.DateTime.cast!("2000-01-01 01:02:03"))
        insert(:survey_log_entry, survey: survey, mode: "ivr",respondent: respondent_1, respondent_hashed_number: "1234", channel: nil, disposition: "partial", action_type: "contact", action_data: "explanation", timestamp: Ecto.DateTime.cast!("2000-01-01 02:03:04"))
        insert(:survey_log_entry, survey: survey, mode: "mobileweb",respondent: respondent_2, respondent_hashed_number: "5678", channel: nil, disposition: "partial", action_type: "contact", action_data: "explanation", timestamp: Ecto.DateTime.cast!("2000-01-01 03:04:05"))
      end

      {:ok, link} = ShortLink.generate_link(Survey.link_name(survey, :results), project_survey_respondents_interactions_path(conn, :interactions, project, survey, %{"_format" => "csv"}))

      respondent_1_interactions_ids = Repo.all(
        from entry in SurveyLogEntry,
          join: r in Respondent, on: entry.respondent_id == r.id,
          where: r.id == ^respondent_1.id,
          order_by: entry.id,
          select: entry.id
      )

      respondent_2_interactions_ids = Repo.all(
        from entry in SurveyLogEntry,
          join: r in Respondent, on: entry.respondent_id == r.id,
          where: r.id == ^respondent_2.id,
          order_by: entry.id,
          select: entry.id
      )

      conn = get conn, short_link_path(conn, :access, link.hash)
      # conn = get conn, project_survey_respondents_interactions_path(conn, :interactions, survey.project.id, survey.id, %{"_format" => "csv"})
      csv = response(conn, 200)

      expected_list = List.flatten(
        ["ID,Respondent ID,Mode,Channel,Disposition,Action Type,Action Data,Timestamp",
        for i <- 0..199 do
          interaction_id = respondent_1_interactions_ids |> Enum.at(i)
          "#{interaction_id},1234,IVR,,Partial,Contact attempt,explanation,2000-01-01 02:03:04 UTC"
        end,
        for i <- 0..199 do
          interaction_id_sms = respondent_2_interactions_ids |> Enum.at(2*i)
          interaction_id_web = respondent_2_interactions_ids |> Enum.at(2*i+1)
          ["#{interaction_id_sms},5678,SMS,test_channel,Completed,Prompt,explanation,2000-01-01 01:02:03 UTC",
          "#{interaction_id_web},5678,Mobile Web,,Partial,Contact attempt,explanation,2000-01-01 03:04:05 UTC"]
        end,
      ])
      lines = csv |> String.split("\r\n") |> Enum.reject(fn x -> String.length(x) == 0 end)
      assert length(lines) == length(expected_list)
      assert lines == expected_list
    end

    test "generates log when downloading interactions csv", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey = insert(:survey, project: project, cutoff: 4, questionnaires: [questionnaire], state: "ready", schedule: completed_schedule())

      remote_ip = {192, 168, 0, 128}
      remote_ip_string = "192.168.0.128"
      conn = conn |> Map.put(:remote_ip, remote_ip)

      {:ok, link} = ShortLink.generate_link(Survey.link_name(survey, :interactions), project_survey_respondents_interactions_path(conn, :interactions, project, survey, %{"_format" => "csv"}))
      get conn, short_link_path(conn, :access, link.hash)

      assert_download_log(%{log: ActivityLog |> Repo.one,
        user: user,
        project: project,
        survey: survey,
        report_type: "interactions",
        remote_ip: remote_ip_string
      })
    end

  end

  def completed_schedule() do
    Ask.Schedule.always()
  end

  defp assert_download_log(%{log: log, project: project, survey: survey, report_type: report_type, remote_ip: remote_ip}) do
    assert log.project_id == project.id
    assert log.user_id == nil
    assert log.entity_id == survey.id
    assert log.entity_type == "survey"
    assert log.action == "download"
    assert log.remote_ip == remote_ip

    assert log.metadata == %{
      "survey_name" => survey.name,
      "report_type" => report_type
    }
  end

  defp user(%{conn: conn}) do
    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn, user: user}
  end
end
