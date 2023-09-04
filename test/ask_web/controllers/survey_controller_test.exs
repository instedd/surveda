defmodule AskWeb.SurveyControllerTest do
  use AskWeb.ConnCase
  use Ask.TestHelpers
  use Ask.DummySteps
  use Ask.MockTime

  alias Ask.{
    Survey,
    Project,
    RespondentGroup,
    Respondent,
    Response,
    Channel,
    SurveyQuestionnaire,
    RespondentDispositionHistory,
    TestChannel,
    RespondentGroupChannel,
    ShortLink,
    ActivityLog
  }

  alias Ask.Runtime.{Flow, Session, ChannelStatusServer}
  alias Ask.Runtime.SessionModeProvider

  @valid_attrs %{name: "some content", description: "initial survey"}
  @invalid_attrs %{cutoff: -1}

  setup %{conn: conn} do
    on_exit(fn ->
      ChannelBrokerSupervisor.terminate_children()
      ChannelBrokerAgent.clear()
    end)

    user = insert(:user)

    conn =
      conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "returns code 200 and empty list if there are no entries", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      conn = get(conn, project_survey_path(conn, :index, project.id))

      assert json_response(conn, 200)["data"] == []
    end

    test "lists surveys", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      started_at = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
      ended_at = Timex.parse!("2016-01-15T10:00:00Z", "{ISO:Extended}")

      survey =
        insert(:survey,
          project: project,
          started_at: started_at,
          ended_at: ended_at,
          description: "initial description"
        )

      survey = Survey |> Repo.get(survey.id)

      conn = get(conn, project_survey_path(conn, :index, project.id))

      assert json_response(conn, 200)["data"] == [
               %{
                 "cutoff" => survey.cutoff,
                 "id" => survey.id,
                 "mode" => survey.mode,
                 "name" => survey.name,
                 "description" => survey.description,
                 "project_id" => project.id,
                 "state" => "not_ready",
                 "locked" => false,
                 "exit_code" => nil,
                 "exit_message" => nil,
                 "schedule" => %{
                   "blocked_days" => [],
                   "day_of_week" => %{
                     "fri" => true,
                     "mon" => true,
                     "sat" => true,
                     "sun" => true,
                     "thu" => true,
                     "tue" => true,
                     "wed" => true
                   },
                   "end_time" => "23:59:59",
                   "start_time" => "00:00:00",
                   "start_date" => nil,
                   "end_date" => nil,
                   "timezone" => "Etc/UTC"
                 },
                 "next_schedule_time" => nil,
                 "started_at" => started_at |> Timex.format!("%FT%T%:z", :strftime),
                 "ended_at" => ended_at |> Timex.format!("%FT%T%:z", :strftime),
                 "updated_at" => to_iso8601(survey.updated_at),
                 "down_channels" => [],
                 "folder_id" => nil,
                 "first_window_started_at" => nil,
                 "panel_survey_id" => nil,
                 "last_window_ends_at" => nil,
                 "is_deletable" => true,
                 "is_movable" => true,
                 "generates_panel_survey" => false
               }
             ]
    end

    test "list only running surveys", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      insert(:survey, project: project, state: :terminated, exit_code: 0)
      survey = insert(:survey, project: project, state: :running)
      survey = Survey |> Repo.get(survey.id)

      conn = get(conn, project_survey_path(conn, :index, project.id, state: :running))

      assert json_response(conn, 200)["data"] == [
               %{
                 "cutoff" => survey.cutoff,
                 "id" => survey.id,
                 "mode" => survey.mode,
                 "name" => survey.name,
                 "description" => nil,
                 "project_id" => project.id,
                 "state" => "running",
                 "locked" => false,
                 "exit_code" => nil,
                 "exit_message" => nil,
                 "schedule" => %{
                   "blocked_days" => [],
                   "day_of_week" => %{
                     "fri" => true,
                     "mon" => true,
                     "sat" => true,
                     "sun" => true,
                     "thu" => true,
                     "tue" => true,
                     "wed" => true
                   },
                   "end_time" => "23:59:59",
                   "start_time" => "00:00:00",
                   "start_date" => nil,
                   "end_date" => nil,
                   "timezone" => "Etc/UTC"
                 },
                 "next_schedule_time" => nil,
                 "started_at" => nil,
                 "ended_at" => nil,
                 "updated_at" => to_iso8601(survey.updated_at),
                 "down_channels" => [],
                 "folder_id" => nil,
                 "first_window_started_at" => nil,
                 "panel_survey_id" => nil,
                 "last_window_ends_at" => nil,
                 "is_deletable" => false,
                 "is_movable" => true,
                 "generates_panel_survey" => false
               }
             ]
    end

    test "won't list surveys inside a folder", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      folder = insert(:folder, project: project)
      started_at = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")

      insert(:survey,
        project: project,
        folder: folder,
        started_at: started_at,
        description: "initial description"
      )

      conn = get(conn, project_survey_path(conn, :index, project.id))

      assert json_response(conn, 200)["data"] == []
    end

    test "won't list surveys that belong to a panel survey", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      panel_survey = insert(:panel_survey, project: project)
      insert(:survey, project: project, panel_survey: panel_survey)

      conn = get(conn, project_survey_path(conn, :index, project.id))

      assert json_response(conn, 200)["data"] == []
    end

    test "list only completed surveys", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      insert(:survey, project: project, state: :running)
      survey = insert(:survey, project: project, state: :terminated, exit_code: 0)
      survey = Survey |> Repo.get(survey.id)

      conn = get(conn, project_survey_path(conn, :index, project.id, state: :completed))

      assert json_response(conn, 200)["data"] == [
               %{
                 "cutoff" => survey.cutoff,
                 "id" => survey.id,
                 "mode" => survey.mode,
                 "name" => survey.name,
                 "description" => nil,
                 "project_id" => project.id,
                 "state" => "terminated",
                 "locked" => false,
                 "exit_code" => 0,
                 "exit_message" => nil,
                 "schedule" => %{
                   "blocked_days" => [],
                   "day_of_week" => %{
                     "fri" => true,
                     "mon" => true,
                     "sat" => true,
                     "sun" => true,
                     "thu" => true,
                     "tue" => true,
                     "wed" => true
                   },
                   "end_time" => "23:59:59",
                   "start_time" => "00:00:00",
                   "start_date" => nil,
                   "end_date" => nil,
                   "timezone" => "Etc/UTC"
                 },
                 "next_schedule_time" => nil,
                 "started_at" => nil,
                 "ended_at" => nil,
                 "updated_at" => to_iso8601(survey.updated_at),
                 "down_channels" => [],
                 "folder_id" => nil,
                 "first_window_started_at" => nil,
                 "panel_survey_id" => nil,
                 "last_window_ends_at" => nil,
                 "is_deletable" => true,
                 "is_movable" => true,
                 "generates_panel_survey" => false
               }
             ]
    end

    test "list surveys with filter by update timestamp", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      insert(:survey, project: project)

      survey =
        insert(:survey,
          project: project,
          updated_at: Timex.shift(Timex.now(), hours: 2, minutes: 3),
          state: :running
        )

      survey = Survey |> Repo.get(survey.id)

      conn =
        get(
          conn,
          project_survey_path(conn, :index, project.id, %{
            "since" => Timex.format!(Timex.shift(Timex.now(), hours: 2), "%FT%T%:z", :strftime)
          })
        )

      assert json_response(conn, 200)["data"] == [
               %{
                 "cutoff" => survey.cutoff,
                 "id" => survey.id,
                 "mode" => survey.mode,
                 "name" => survey.name,
                 "description" => nil,
                 "project_id" => project.id,
                 "state" => "running",
                 "locked" => false,
                 "exit_code" => nil,
                 "exit_message" => nil,
                 "schedule" => %{
                   "blocked_days" => [],
                   "day_of_week" => %{
                     "fri" => true,
                     "mon" => true,
                     "sat" => true,
                     "sun" => true,
                     "thu" => true,
                     "tue" => true,
                     "wed" => true
                   },
                   "end_time" => "23:59:59",
                   "start_time" => "00:00:00",
                   "start_date" => nil,
                   "end_date" => nil,
                   "timezone" => "Etc/UTC"
                 },
                 "next_schedule_time" => nil,
                 "started_at" => nil,
                 "ended_at" => nil,
                 "updated_at" => to_iso8601(survey.updated_at),
                 "down_channels" => [],
                 "folder_id" => nil,
                 "first_window_started_at" => nil,
                 "panel_survey_id" => nil,
                 "last_window_ends_at" => nil,
                 "is_deletable" => false,
                 "is_movable" => true,
                 "generates_panel_survey" => false
               }
             ]
    end

    test "list surveys with down_channels", %{conn: conn, user: user} do
      {:ok, pid} = ChannelStatusServer.start_link()
      Process.register(self(), :mail_target)

      project = create_project_for_user(user)
      survey_1 = insert(:survey, project: project, state: :running)
      survey_2 = insert(:survey, project: project, state: :running)
      survey_3 = insert(:survey, project: project, state: :running)

      up_channel =
        TestChannel.create_channel(user, "test", TestChannel.settings(TestChannel.new(), 1))

      down_channel =
        TestChannel.create_channel(
          user,
          "test",
          TestChannel.settings(TestChannel.new(), 2, :down)
        )

      error_channel =
        TestChannel.create_channel(
          user,
          "test",
          TestChannel.settings(TestChannel.new(), 3, :error)
        )

      setup_surveys_with_channels([survey_1, survey_2, survey_3], [
        up_channel,
        down_channel,
        error_channel
      ])

      ChannelStatusServer.poll(pid)

      conn = get(conn, project_survey_path(conn, :index, project.id))

      [survey_1, survey_2, survey_3] = json_response(conn, 200)["data"]
      assert survey_1["down_channels"] == []

      [%{"status" => "down", "messages" => [], "timestamp" => t1, "name" => "test"}] =
        survey_2["down_channels"]

      assert t1

      [%{"status" => "error", "code" => code, "timestamp" => t2, "name" => "test"}] =
        survey_3["down_channels"]

      assert t2
      assert code

      ChannelBrokerSupervisor.terminate_children()
      ChannelBrokerAgent.clear()
    end

    test "returns 404 when the project does not exist", %{conn: conn} do
      assert_error_sent 404, fn ->
        get(conn, project_survey_path(conn, :index, -1))
      end
    end

    test "forbid index access if the project does not belong to the current user", %{conn: conn} do
      survey = insert(:survey)

      assert_error_sent :forbidden, fn ->
        get(conn, project_survey_path(conn, :index, survey.project))
      end
    end
  end

  describe "show" do
    @tag :time_mock
    test "shows chosen resource", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      survey =
        insert(:survey,
          project: project,
          description: "initial survey",
          state: :terminated,
          started_at: Timex.now(),
          ended_at: Timex.shift(Timex.now(), days: 1)
        )

      survey = Survey |> Repo.get(survey.id)
      mock_time(Timex.shift(Timex.now(), minutes: 10))

      conn = get(conn, project_survey_path(conn, :show, project, survey))

      assert json_response(conn, 200)["data"] == %{
               "id" => survey.id,
               "name" => survey.name,
               "description" => "initial survey",
               "mode" => survey.mode,
               "project_id" => survey.project_id,
               "questionnaire_ids" => [],
               "questionnaires" => %{},
               "cutoff" => nil,
               "count_partial_results" => false,
               "state" => "terminated",
               "locked" => false,
               "exit_code" => nil,
               "exit_message" => nil,
               "schedule" => %{
                 "day_of_week" => %{
                   "fri" => true,
                   "mon" => true,
                   "sat" => true,
                   "sun" => true,
                   "thu" => true,
                   "tue" => true,
                   "wed" => true
                 },
                 "start_time" => "00:00:00",
                 "start_date" => nil,
                 "end_date" => nil,
                 "end_time" => "23:59:59",
                 "timezone" => "Etc/UTC",
                 "blocked_days" => []
               },
               "started_at" => Timex.format!(survey.started_at, "%FT%T%:z", :strftime),
               "ended_at" => Timex.format!(survey.ended_at, "%FT%T%:z", :strftime),
               "ivr_retry_configuration" => nil,
               "sms_retry_configuration" => nil,
               "mobileweb_retry_configuration" => nil,
               "fallback_delay" => nil,
               "updated_at" => to_iso8601(survey.updated_at),
               "quotas" => %{
                 "vars" => [],
                 "buckets" => []
               },
               "links" => [],
               "comparisons" => [],
               "next_schedule_time" => nil,
               "down_channels" => [],
               "folder_id" => nil,
               "incentives_enabled" => true,
               "first_window_started_at" => nil,
               "panel_survey_id" => nil,
               "last_window_ends_at" => nil,
               "generates_panel_survey" => false
             }
    end

    test "includes folder_id when showing the chosen resource", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      folder = insert(:folder, project: project)

      survey =
        insert(:survey,
          project: project,
          folder_id: folder.id,
          description: "initial survey",
          state: "terminated",
          started_at: Timex.now(),
          ended_at: Timex.shift(Timex.now(), days: 1)
        )

      conn = get(conn, project_survey_path(conn, :show, project, survey))

      folder_id = Map.get(json_response(conn, 200)["data"], "folder_id")

      assert folder_id == folder.id
    end

    test "shows chosen resource with buckets", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, quota_vars: ["gender", "smokes"])
      survey = Survey |> Repo.get(survey.id)

      insert(:quota_bucket,
        survey: survey,
        condition: %{gender: "male", smokes: "no"},
        quota: 10,
        count: 3
      )

      insert(:quota_bucket, survey: survey, condition: %{gender: "male", smokes: "yes"}, quota: 20)

      insert(:quota_bucket,
        survey: survey,
        condition: %{gender: "female", smokes: "no"},
        quota: 30,
        count: 1
      )

      insert(:quota_bucket,
        survey: survey,
        condition: %{gender: "female", smokes: "yes"},
        quota: 40
      )

      conn = get(conn, project_survey_path(conn, :show, project, survey))

      assert json_response(conn, 200)["data"] == %{
               "id" => survey.id,
               "name" => survey.name,
               "description" => nil,
               "mode" => survey.mode,
               "project_id" => survey.project_id,
               "questionnaire_ids" => [],
               "cutoff" => nil,
               "count_partial_results" => false,
               "state" => "not_ready",
               "locked" => false,
               "exit_code" => nil,
               "exit_message" => nil,
               "schedule" => %{
                 "day_of_week" => %{
                   "fri" => true,
                   "mon" => true,
                   "sat" => true,
                   "sun" => true,
                   "thu" => true,
                   "tue" => true,
                   "wed" => true
                 },
                 "start_time" => "00:00:00",
                 "start_date" => nil,
                 "end_date" => nil,
                 "end_time" => "23:59:59",
                 "timezone" => "Etc/UTC",
                 "blocked_days" => []
               },
               "started_at" => nil,
               "ended_at" => nil,
               "ivr_retry_configuration" => nil,
               "sms_retry_configuration" => nil,
               "mobileweb_retry_configuration" => nil,
               "fallback_delay" => nil,
               "updated_at" => to_iso8601(survey.updated_at),
               "quotas" => %{
                 "vars" => ["gender", "smokes"],
                 "buckets" => [
                   %{
                     "condition" => [
                       %{"store" => "smokes", "value" => "no"},
                       %{"store" => "gender", "value" => "male"}
                     ],
                     "quota" => 10,
                     "count" => 3
                   },
                   %{
                     "condition" => [
                       %{"store" => "smokes", "value" => "yes"},
                       %{"store" => "gender", "value" => "male"}
                     ],
                     "quota" => 20,
                     "count" => 0
                   },
                   %{
                     "condition" => [
                       %{"store" => "smokes", "value" => "no"},
                       %{"store" => "gender", "value" => "female"}
                     ],
                     "quota" => 30,
                     "count" => 1
                   },
                   %{
                     "condition" => [
                       %{"store" => "smokes", "value" => "yes"},
                       %{"store" => "gender", "value" => "female"}
                     ],
                     "quota" => 40,
                     "count" => 0
                   }
                 ]
               },
               "links" => [],
               "comparisons" => [],
               "next_schedule_time" => nil,
               "down_channels" => [],
               "folder_id" => nil,
               "incentives_enabled" => true,
               "first_window_started_at" => nil,
               "panel_survey_id" => nil,
               "last_window_ends_at" => nil,
               "generates_panel_survey" => false
             }
    end

    test "shows chosen resource with download links", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      survey = Survey |> Repo.get(survey.id)
      {:ok, result_link} = ShortLink.generate_link(Survey.link_name(survey, :results), "foo")

      {:ok, incentives_link} =
        ShortLink.generate_link(Survey.link_name(survey, :incentives), "bar")

      {:ok, interactions_link} =
        ShortLink.generate_link(Survey.link_name(survey, :interactions), "baz")

      {:ok, disposition_history_link} =
        ShortLink.generate_link(Survey.link_name(survey, :disposition_history), "bae")

      conn = get(conn, project_survey_path(conn, :show, project, survey))

      assert json_response(conn, 200)["data"] == %{
               "id" => survey.id,
               "name" => survey.name,
               "description" => nil,
               "mode" => survey.mode,
               "project_id" => survey.project_id,
               "questionnaire_ids" => [],
               "cutoff" => nil,
               "count_partial_results" => false,
               "state" => "not_ready",
               "locked" => false,
               "exit_code" => nil,
               "exit_message" => nil,
               "schedule" => %{
                 "day_of_week" => %{
                   "fri" => true,
                   "mon" => true,
                   "sat" => true,
                   "sun" => true,
                   "thu" => true,
                   "tue" => true,
                   "wed" => true
                 },
                 "start_time" => "00:00:00",
                 "start_date" => nil,
                 "end_date" => nil,
                 "end_time" => "23:59:59",
                 "timezone" => "Etc/UTC",
                 "blocked_days" => []
               },
               "started_at" => nil,
               "ended_at" => nil,
               "ivr_retry_configuration" => nil,
               "sms_retry_configuration" => nil,
               "mobileweb_retry_configuration" => nil,
               "fallback_delay" => nil,
               "updated_at" => to_iso8601(survey.updated_at),
               "quotas" => %{
                 "vars" => [],
                 "buckets" => []
               },
               "links" => [
                 %{
                   "name" => "survey/#{survey.id}/results",
                   "url" => "#{AskWeb.Endpoint.url()}/link/#{result_link.hash}"
                 },
                 %{
                   "name" => "survey/#{survey.id}/incentives",
                   "url" => "#{AskWeb.Endpoint.url()}/link/#{incentives_link.hash}"
                 },
                 %{
                   "name" => "survey/#{survey.id}/interactions",
                   "url" => "#{AskWeb.Endpoint.url()}/link/#{interactions_link.hash}"
                 },
                 %{
                   "name" => "survey/#{survey.id}/disposition_history",
                   "url" => "#{AskWeb.Endpoint.url()}/link/#{disposition_history_link.hash}"
                 }
               ],
               "comparisons" => [],
               "next_schedule_time" => nil,
               "down_channels" => [],
               "folder_id" => nil,
               "incentives_enabled" => true,
               "first_window_started_at" => nil,
               "panel_survey_id" => nil,
               "last_window_ends_at" => nil,
               "generates_panel_survey" => false
             }
    end

    test "shows chosen resource with available links if reader", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      survey = insert(:survey, project: project)
      survey = Survey |> Repo.get(survey.id)
      {:ok, result_link} = ShortLink.generate_link(Survey.link_name(survey, :results), "foo")

      {:ok, _incentives_link} =
        ShortLink.generate_link(Survey.link_name(survey, :incentives), "bar")

      {:ok, _interactions_link} =
        ShortLink.generate_link(Survey.link_name(survey, :interactions), "baz")

      {:ok, disposition_history_link} =
        ShortLink.generate_link(Survey.link_name(survey, :disposition_history), "bae")

      conn = get(conn, project_survey_path(conn, :show, project, survey))

      assert json_response(conn, 200)["data"] == %{
               "id" => survey.id,
               "name" => survey.name,
               "description" => nil,
               "mode" => survey.mode,
               "project_id" => survey.project_id,
               "questionnaire_ids" => [],
               "cutoff" => nil,
               "count_partial_results" => false,
               "state" => "not_ready",
               "locked" => false,
               "exit_code" => nil,
               "exit_message" => nil,
               "schedule" => %{
                 "day_of_week" => %{
                   "fri" => true,
                   "mon" => true,
                   "sat" => true,
                   "sun" => true,
                   "thu" => true,
                   "tue" => true,
                   "wed" => true
                 },
                 "start_time" => "00:00:00",
                 "start_date" => nil,
                 "end_date" => nil,
                 "end_time" => "23:59:59",
                 "timezone" => "Etc/UTC",
                 "blocked_days" => []
               },
               "started_at" => nil,
               "ended_at" => nil,
               "ivr_retry_configuration" => nil,
               "sms_retry_configuration" => nil,
               "mobileweb_retry_configuration" => nil,
               "fallback_delay" => nil,
               "updated_at" => to_iso8601(survey.updated_at),
               "quotas" => %{
                 "vars" => [],
                 "buckets" => []
               },
               "links" => [
                 %{
                   "name" => "survey/#{survey.id}/results",
                   "url" => "#{AskWeb.Endpoint.url()}/link/#{result_link.hash}"
                 },
                 %{
                   "name" => "survey/#{survey.id}/disposition_history",
                   "url" => "#{AskWeb.Endpoint.url()}/link/#{disposition_history_link.hash}"
                 }
               ],
               "comparisons" => [],
               "next_schedule_time" => nil,
               "down_channels" => [],
               "folder_id" => nil,
               "incentives_enabled" => true,
               "first_window_started_at" => nil,
               "panel_survey_id" => nil,
               "last_window_ends_at" => nil,
               "generates_panel_survey" => false
             }
    end

    test "shows channels status when survey is running", %{conn: conn, user: user} do
      {:ok, pid} = ChannelStatusServer.start_link()
      Process.register(self(), :mail_target)

      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: :running)
      survey = Survey |> Repo.get(survey.id)

      up_channel =
        TestChannel.create_channel(user, "test", TestChannel.settings(TestChannel.new(), 1))

      down_channel =
        TestChannel.create_channel(
          user,
          "test",
          TestChannel.settings(TestChannel.new(), 2, :down)
        )

      error_channel =
        TestChannel.create_channel(
          user,
          "test",
          TestChannel.settings(TestChannel.new(), 3, :error)
        )

      group_1 = insert(:respondent_group, survey: survey)
      group_2 = insert(:respondent_group, survey: survey)
      group_3 = insert(:respondent_group, survey: survey)

      insert(:respondent_group_channel,
        channel: up_channel,
        respondent_group: group_1,
        mode: "sms"
      )

      insert(:respondent_group_channel,
        channel: down_channel,
        respondent_group: group_2,
        mode: "sms"
      )

      insert(:respondent_group_channel,
        channel: error_channel,
        respondent_group: group_3,
        mode: "sms"
      )

      ChannelStatusServer.poll(pid)

      conn = get(conn, project_survey_path(conn, :show, project, survey))

      data = json_response(conn, 200)["data"]

      [
        %{"status" => "down", "messages" => [], "timestamp" => t1, "name" => "test"},
        %{"status" => "error", "code" => "some code", "timestamp" => t2, "name" => "test"}
      ] = data["down_channels"]

      assert t1
      assert t2

      ChannelBrokerSupervisor.terminate_children()
      ChannelBrokerAgent.clear()
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent 404, fn ->
        get(conn, project_survey_path(conn, :show, -1, -1))
      end
    end

    test "forbid access to survey if the project does not belong to the current user", %{
      conn: conn
    } do
      survey = insert(:survey)

      assert_error_sent :forbidden, fn ->
        get(conn, project_survey_path(conn, :show, survey.project, survey))
      end
    end
  end

  describe "stats" do
    test "show survey stats when there's no respondent", %{conn: conn, user: user} do
      %{
        "success_rate" => 0.0,
        "completion_rate" => 0.0,
        "initial_success_rate" => 1.0,
        "estimated_success_rate" => 1.0,
        "exhausted" => 0,
        "available" => 0,
        "additional_completes" => 0,
        "needed_to_complete" => 0,
        "additional_respondents" => 0
      } =
        testing_survey(%{user: user, respondents: []})
        |> get_stats(conn)
    end

    test "measures the completion rate when it's completed", %{conn: conn, user: user} do
      respondents = Enum.map(["completed"], fn disposition -> %{disposition: disposition} end)

      %{"completion_rate" => 1.0} =
        testing_survey(%{user: user, respondents: respondents})
        |> get_stats(conn)
    end

    test "measures the completion rate when it isn't completed", %{conn: conn, user: user} do
      respondents =
        Enum.map(["completed", "queued", "started"], fn disposition ->
          %{disposition: disposition}
        end)

      %{"completion_rate" => 0.333} =
        testing_survey(%{user: user, respondents: respondents})
        |> get_stats(conn)
    end

    test "estimated success rate equals current when completed", %{conn: conn, user: user} do
      respondents =
        Enum.map(1..2, fn _ -> %{disposition: "completed"} end) ++ [%{disposition: "failed"}]

      %{
        "success_rate" => 0.667,
        "completion_rate" => 1.0,
        "estimated_success_rate" => 0.667
      } =
        testing_survey(%{user: user, respondents: respondents, attrs: %{cutoff: 2}})
        |> get_stats(conn)
    end

    test "estimated success rate averages initial and current when completion rate is 50%", %{
      conn: conn,
      user: user
    } do
      respondents = [%{disposition: "failed"}, %{disposition: "completed"}]

      %{
        "completion_rate" => 0.5,
        "initial_success_rate" => 1.0,
        "success_rate" => 0.5,
        "estimated_success_rate" => 0.75
      } =
        testing_survey(%{user: user, respondents: respondents})
        |> get_stats(conn)
    end

    test "estimated success rate is calculated using linear interpolation", %{
      conn: conn,
      user: user
    } do
      respondents =
        Enum.map(1..3, fn _ -> %{disposition: "failed"} end) ++ [%{disposition: "completed"}]

      %{"estimated_success_rate" => 0.85} =
        testing_survey(%{user: user, respondents: respondents, attrs: %{cutoff: 5}})
        |> get_stats(conn)
    end

    test "additional respondents are never less than zero", %{conn: conn, user: user} do
      respondents = Enum.map(1..2, fn _ -> %{disposition: "queued"} end)

      %{"additional_respondents" => 0} =
        testing_survey(%{user: user, respondents: respondents, attrs: %{cutoff: 1}})
        |> get_stats(conn)
    end

    test "expose correctly respondents in final dispositions", %{conn: conn, user: user} do
      final_dispositions = Respondent.metrics_final_dispositions()

      respondents =
        Enum.map(final_dispositions, fn disposition -> %{disposition: disposition} end)

      %{"exhausted" => exhausted, "available" => 0} =
        testing_survey(%{user: user, respondents: respondents})
        |> get_stats(conn)

      assert exhausted == Enum.count(final_dispositions)
    end

    test "expose correctly respondents in non final dispositions", %{conn: conn, user: user} do
      non_final_dispositions = Respondent.metrics_non_final_dispositions()

      respondents =
        Enum.map(non_final_dispositions, fn disposition -> %{disposition: disposition} end)

      %{"exhausted" => 0, "available" => available} =
        testing_survey(%{user: user, respondents: respondents})
        |> get_stats(conn)

      assert available == Enum.count(non_final_dispositions)
    end

    test "needed to complete is zero when completed", %{conn: conn, user: user} do
      respondents = [%{disposition: "completed"}]

      %{"needed_to_complete" => 0} =
        testing_survey(%{user: user, respondents: respondents})
        |> get_stats(conn)
    end

    test "needed to complete equals target with no respondents", %{conn: conn, user: user} do
      %{"needed_to_complete" => 5} =
        testing_survey(%{user: user, respondents: [], attrs: %{cutoff: 5}})
        |> get_stats(conn)
    end

    test "additional_completes equals target - completed respondents", %{conn: conn, user: user} do
      respondents =
        Enum.map(["completed", "completed", "queued"], fn disposition ->
          %{disposition: disposition}
        end)

      %{"additional_completes" => 3} =
        testing_survey(%{user: user, respondents: respondents, attrs: %{cutoff: 5}})
        |> get_stats(conn)
    end

    test "needed to complete duplicates additional to complete when estimated success rate is 50%",
         %{conn: conn, user: user} do
      respondents =
        Enum.map(1..99, fn _ -> %{disposition: "completed"} end) ++
          Enum.map(1..99, fn _ -> %{disposition: "failed"} end)

      %{"additional_completes" => 1, "needed_to_complete" => 2} =
        testing_survey(%{user: user, respondents: respondents, attrs: %{cutoff: 100}})
        |> get_stats(conn)
    end

    test "needed to complete equals additional_completes when estimated success rate is 100%", %{
      conn: conn,
      user: user
    } do
      respondents = [%{disposition: "completed"}]

      %{"additional_completes" => 1, "needed_to_complete" => 1} =
        testing_survey(%{user: user, respondents: respondents, attrs: %{cutoff: 2}})
        |> get_stats(conn)
    end

    test "additional respondents equals needed to complete - respondents in non final dispositions",
         %{conn: conn, user: user} do
      non_final_dispositions = Respondent.metrics_non_final_dispositions()

      respondents =
        [%{disposition: :completed}] ++
          Enum.map(non_final_dispositions, fn disposition -> %{disposition: disposition} end)

      %{"needed_to_complete" => 100, "additional_respondents" => additional_respondents} =
        testing_survey(%{user: user, respondents: respondents, attrs: %{cutoff: 101}})
        |> get_stats(conn)

      assert additional_respondents == 100 - Enum.count(non_final_dispositions)
    end

    test "additional respondents depends on needed to complete (it doesn't depend on additional_completes)",
         %{conn: conn, user: user} do
      non_final_dispositions = Respondent.metrics_non_final_dispositions()

      respondents =
        Enum.map(1..100, fn _ -> %{disposition: "completed"} end) ++
          Enum.map(1..100, fn _ -> %{disposition: "failed"} end) ++
          Enum.map(non_final_dispositions, fn disposition -> %{disposition: disposition} end)

      %{
        "needed_to_complete" => 18,
        "additional_completes" => 10,
        "additional_respondents" => additional_respondents
      } =
        testing_survey(%{user: user, respondents: respondents, attrs: %{cutoff: 110}})
        |> get_stats(conn)

      assert additional_respondents == 18 - Enum.count(non_final_dispositions)
    end
  end

  describe "count_partial_results stats" do
    setup %{conn: conn, user: user} do
      survey =
        count_partial_results_test_survey(%{
          count_partial_results: false,
          disposition: "completed",
          user: user
        })

      completed_test_case_stats = get_stats(survey, conn)

      {:ok, conn: conn, user: user, completed_test_case_stats: completed_test_case_stats}
    end

    test "treats completed as expected",
         %{completed_test_case_stats: completed_test_case_stats} do
      %{
        "initial_success_rate" => initial_success_rate,
        "completion_rate" => completion_rate,
        "success_rate" => success_rate,
        "estimated_success_rate" => estimated_success_rate,
        "needed_to_complete" => needed_to_complete,
        "available" => available,
        "additional_respondents" => additional_respondents
      } = completed_test_case_stats

      assert initial_success_rate == 1
      assert completion_rate == 0.333
      assert success_rate == 0.5
      assert estimated_success_rate == 0.833
      assert needed_to_complete == 2
      assert available == 1
      assert additional_respondents == 1
    end

    test "treats partial as completed when count_partial_results",
         %{conn: conn, user: user, completed_test_case_stats: completed_test_case_stats} do
      survey =
        count_partial_results_test_survey(%{
          count_partial_results: true,
          disposition: "partial",
          user: user
        })

      stats = get_stats(survey, conn)

      assert stats == completed_test_case_stats
    end

    test "treats interim partial as completed when count_partial_results",
         %{conn: conn, user: user, completed_test_case_stats: completed_test_case_stats} do
      survey =
        count_partial_results_test_survey(%{
          count_partial_results: true,
          disposition: "interim partial",
          user: user
        })

      stats = get_stats(survey, conn)

      assert stats == completed_test_case_stats
    end

    test "doesn't treat partial as completed when not count_partial_results",
         %{conn: conn, user: user, completed_test_case_stats: completed_test_case_stats} do
      survey =
        count_partial_results_test_survey(%{
          count_partial_results: false,
          disposition: "partial",
          user: user
        })

      stats = get_stats(survey, conn)

      refute stats == completed_test_case_stats
    end

    test "doesn't treat interim partial as completed when not count_partial_results",
         %{conn: conn, user: user, completed_test_case_stats: completed_test_case_stats} do
      survey =
        count_partial_results_test_survey(%{
          count_partial_results: false,
          disposition: "interim partial",
          user: user
        })

      stats = get_stats(survey, conn)

      refute stats == completed_test_case_stats
    end
  end

  defp count_partial_results_test_survey(%{
         count_partial_results: count_partial_results,
         disposition: disposition,
         user: user
       }) do
    respondents =
      Enum.map(
        [disposition, "failed", "started"],
        fn disposition -> %{disposition: disposition} end
      )

    testing_survey(%{
      user: user,
      respondents: respondents,
      attrs: %{count_partial_results: count_partial_results}
    })
  end

  defp get_stats(%{survey: survey, project: project}, conn) do
    conn = get(conn, project_survey_survey_path(conn, :stats, project, survey))
    json_response(conn, 200)["data"]
  end

  defp testing_survey(%{user: user, respondents: respondents, attrs: attrs}) do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project)
    survey = if attrs, do: Survey.changeset(survey, attrs) |> Repo.update!(), else: survey

    Enum.each(respondents, fn %{disposition: disposition} ->
      insert(:respondent, survey: survey, disposition: disposition)
    end)

    %{project: project, survey: survey}
  end

  defp testing_survey(%{user: user, respondents: respondents}),
    do: testing_survey(%{user: user, respondents: respondents, attrs: nil})

  test "retries histograms", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project, fallback_delay: "2h")

    conn = get(conn, project_survey_survey_path(conn, :retries_histograms, project, survey))
    response = json_response(conn, 200)["data"]

    assert response == [
             %{
               "actives" => [],
               "flow" => [
                 %{"delay" => 0, "type" => "sms"},
                 %{"delay" => 2, "type" => "end", "label" => "2h"}
               ]
             }
           ]
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get(conn, project_survey_path(conn, :show, -1, -1))
    end
  end

  test "forbid access to survey if the project does not belong to the current user", %{conn: conn} do
    survey = insert(:survey)

    assert_error_sent :forbidden, fn ->
      get(conn, project_survey_path(conn, :show, survey.project, survey))
    end
  end

  describe "create" do
    test "creates and renders resource when data is valid", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      conn = post(conn, project_survey_path(conn, :create, project.id))

      assert json_response(conn, 201)["data"]["id"]
      assert Repo.get_by(Survey, %{project_id: project.id})
    end

    test "creates the survey inside the requested folder", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      folder = insert(:folder, project: project)

      conn = post(conn, project_folder_survey_path(conn, :create, project.id, folder.id))

      survey_id = json_response(conn, 201)["data"]["id"]
      assert survey_id
      survey = Survey |> Repo.get(survey_id)
      assert survey

      %{folder_id: folder_id, project_id: project_id} = survey
      assert folder_id == folder.id
      assert project_id == project.id
    end

    test "forbids creation of survey for a project that belongs to another user", %{conn: conn} do
      project = insert(:project)

      assert_error_sent :forbidden, fn ->
        post conn, project_survey_path(conn, :create, project.id), survey: @valid_attrs
      end
    end

    test "forbids creation of survey for a project reader", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")

      assert_error_sent :forbidden, fn ->
        post conn, project_survey_path(conn, :create, project.id), survey: @valid_attrs
      end
    end

    test "updates project updated_at when survey is created", %{conn: conn, user: user} do
      {:ok, datetime, _} = DateTime.from_iso8601("2000-01-01T00:00:00Z")
      project = create_project_for_user(user, updated_at: datetime)
      post(conn, project_survey_path(conn, :create, project.id))

      project = Project |> Repo.get(project.id)

      # 1 -- the first date comes after the second one
      assert Timex.compare(project.updated_at, datetime) == 1
    end

    test "forbids creation if project is archived", %{conn: conn, user: user} do
      project = create_project_for_user(user, archived: true)

      assert_error_sent :forbidden, fn ->
        post(conn, project_survey_path(conn, :create, project.id))
      end
    end
  end

  describe "update" do
    test "updates and renders chosen resource when data is valid", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      conn = put conn, project_survey_path(conn, :update, project, survey), survey: @valid_attrs

      assert json_response(conn, 200)["data"]["id"]
      assert Repo.get_by(Survey, @valid_attrs)
    end

    test "updates schedule when data is valid", %{conn: conn, user: user} do
      [project, questionnaire, _] = prepare_for_state_update(user)
      survey = insert(:survey, project: project, questionnaires: [questionnaire])

      conn =
        put conn, project_survey_path(conn, :update, project, survey),
          survey: %{schedule: completed_schedule()}

      assert json_response(conn, 200)["data"]["schedule"]["day_of_week"]["sun"] == true
    end

    test "updates cutoff when channels are included in params", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)
      survey = insert(:survey, project: project, questionnaires: [questionnaire])
      create_group(survey, channel)

      conn =
        put conn, project_survey_path(conn, :update, project, survey),
          survey: %{cutoff: 4, channels: [channel.id]}

      assert json_response(conn, 200)["data"]["cutoff"] == 4
    end

    test "does not update chosen resource and renders errors when data is invalid", %{
      conn: conn,
      user: user
    } do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      conn =
        put conn, project_survey_path(conn, :update, survey.project, survey),
          survey: @invalid_attrs

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "saves quota_buckets and quota_vars", %{conn: conn, user: user} do
      [project, questionnaire, _] = prepare_for_state_update(user)
      survey = insert(:survey, project: project, questionnaires: [questionnaire])

      conn2 =
        put conn, project_survey_path(conn, :update, project, survey),
          survey: %{
            quotas: %{
              vars: ["Smokes", "Exercises"],
              buckets: [
                %{
                  "condition" => [
                    %{"store" => "Exercises", "value" => "No"},
                    %{"store" => "Smokes", "value" => "No"}
                  ],
                  "quota" => 10,
                  "count" => 3
                },
                %{
                  "condition" => [
                    %{"store" => "Exercises", "value" => "No"},
                    %{"store" => "Smokes", "value" => "Yes"}
                  ],
                  "quota" => 20
                },
                %{
                  "condition" => [
                    %{"store" => "Exercises", "value" => "Yes"},
                    %{"store" => "Smokes", "value" => "No"}
                  ],
                  "quota" => 30
                },
                %{
                  "condition" => [
                    %{"store" => "Exercises", "value" => "Yes"},
                    %{"store" => "Smokes", "value" => "Yes"}
                  ],
                  "quota" => 40
                }
              ]
            }
          }

      assert json_response(conn2, 200)["data"]["quotas"]["vars"] == ["Smokes", "Exercises"]

      assert json_response(conn2, 200)["data"]["quotas"]["buckets"] == [
               %{
                 "condition" => [
                   %{"store" => "Smokes", "value" => "No"},
                   %{"store" => "Exercises", "value" => "No"}
                 ],
                 "quota" => 10,
                 "count" => 3
               },
               %{
                 "condition" => [
                   %{"store" => "Smokes", "value" => "Yes"},
                   %{"store" => "Exercises", "value" => "No"}
                 ],
                 "quota" => 20,
                 "count" => 0
               },
               %{
                 "condition" => [
                   %{"store" => "Smokes", "value" => "No"},
                   %{"store" => "Exercises", "value" => "Yes"}
                 ],
                 "quota" => 30,
                 "count" => 0
               },
               %{
                 "condition" => [
                   %{"store" => "Smokes", "value" => "Yes"},
                   %{"store" => "Exercises", "value" => "Yes"}
                 ],
                 "quota" => 40,
                 "count" => 0
               }
             ]

      conn = get(conn, project_survey_path(conn, :show, project, survey))

      assert json_response(conn, 200)["data"]["quotas"] == %{
               "vars" => ["Smokes", "Exercises"],
               "buckets" => [
                 %{
                   "condition" => [
                     %{"store" => "Smokes", "value" => "No"},
                     %{"store" => "Exercises", "value" => "No"}
                   ],
                   "quota" => 10,
                   "count" => 3
                 },
                 %{
                   "condition" => [
                     %{"store" => "Smokes", "value" => "Yes"},
                     %{"store" => "Exercises", "value" => "No"}
                   ],
                   "quota" => 20,
                   "count" => 0
                 },
                 %{
                   "condition" => [
                     %{"store" => "Smokes", "value" => "No"},
                     %{"store" => "Exercises", "value" => "Yes"}
                   ],
                   "quota" => 30,
                   "count" => 0
                 },
                 %{
                   "condition" => [
                     %{"store" => "Smokes", "value" => "Yes"},
                     %{"store" => "Exercises", "value" => "Yes"}
                   ],
                   "quota" => 40,
                   "count" => 0
                 }
               ]
             }
    end

    test "replaces quota_buckets when vars are updated", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, quota_vars: ["gender", "smokes"])

      insert(:quota_bucket,
        survey: survey,
        condition: %{gender: "male", smokes: "no"},
        quota: 10,
        count: 3
      )

      insert(:quota_bucket, survey: survey, condition: %{gender: "male", smokes: "yes"}, quota: 20)

      insert(:quota_bucket,
        survey: survey,
        condition: %{gender: "female", smokes: "no"},
        quota: 30,
        count: 1
      )

      insert(:quota_bucket,
        survey: survey,
        condition: %{gender: "female", smokes: "yes"},
        quota: 40
      )

      conn =
        put conn, project_survey_path(conn, :update, project, survey),
          survey: %{
            quotas: %{
              vars: ["Exercises", "Smokes"],
              buckets: [
                %{
                  "condition" => [
                    %{"store" => "Exercises", "value" => "No"},
                    %{"store" => "Smokes", "value" => "No"}
                  ],
                  "quota" => 10,
                  "count" => 3
                },
                %{
                  "condition" => [
                    %{"store" => "Exercises", "value" => "No"},
                    %{"store" => "Smokes", "value" => "Yes"}
                  ],
                  "quota" => 20
                },
                %{
                  "condition" => [
                    %{"store" => "Exercises", "value" => "Yes"},
                    %{"store" => "Smokes", "value" => "No"}
                  ],
                  "quota" => 30
                },
                %{
                  "condition" => [
                    %{"store" => "Exercises", "value" => "Yes"},
                    %{"store" => "Smokes", "value" => "Yes"}
                  ],
                  "quota" => 40
                }
              ]
            }
          }

      assert json_response(conn, 200)["data"]["quotas"]["vars"] == ["Exercises", "Smokes"]

      assert json_response(conn, 200)["data"]["quotas"]["buckets"] == [
               %{
                 "condition" => [
                   %{"store" => "Smokes", "value" => "No"},
                   %{"store" => "Exercises", "value" => "No"}
                 ],
                 "quota" => 10,
                 "count" => 3
               },
               %{
                 "condition" => [
                   %{"store" => "Smokes", "value" => "Yes"},
                   %{"store" => "Exercises", "value" => "No"}
                 ],
                 "quota" => 20,
                 "count" => 0
               },
               %{
                 "condition" => [
                   %{"store" => "Smokes", "value" => "No"},
                   %{"store" => "Exercises", "value" => "Yes"}
                 ],
                 "quota" => 30,
                 "count" => 0
               },
               %{
                 "condition" => [
                   %{"store" => "Smokes", "value" => "Yes"},
                   %{"store" => "Exercises", "value" => "Yes"}
                 ],
                 "quota" => 40,
                 "count" => 0
               }
             ]
    end

    test "rejects update if the survey doesn't belong to the current user", %{conn: conn} do
      survey = insert(:survey)

      assert_error_sent :forbidden, fn ->
        put conn, project_survey_path(conn, :update, survey.project, survey),
          survey: @invalid_attrs
      end
    end

    test "rejects update for a project reader", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      survey = insert(:survey, project: project)

      assert_error_sent :forbidden, fn ->
        put conn, project_survey_path(conn, :update, survey.project, survey),
          survey: @invalid_attrs
      end
    end

    test "rejects update if project is archived", %{conn: conn, user: user} do
      project = create_project_for_user(user, archived: true)
      survey = insert(:survey, project: project)

      assert_error_sent :forbidden, fn ->
        put conn, project_survey_path(conn, :update, survey.project, survey),
          survey: @invalid_attrs
      end
    end

    test "fails if the schedule from is greater or equal to the to", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      conn =
        put conn, project_survey_path(conn, :update, project, survey),
          survey:
            Map.merge(@valid_attrs, %{
              schedule:
                Map.merge(Ask.Schedule.default(), %{
                  start_time: ~T[02:00:00],
                  end_time: ~T[01:00:00]
                })
            })

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "schedule to and from are saved successfully", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      conn =
        put conn, project_survey_path(conn, :update, project, survey),
          survey:
            Map.merge(@valid_attrs, %{
              schedule: %{
                start_time: "01:00:00",
                end_time: "02:00:00",
                blocked_days: [],
                timezone: "Etc/UTC",
                day_of_week: Ask.DayOfWeek.every_day()
              }
            })

      assert json_response(conn, 200)
      created_survey = Repo.get_by(Survey, %{project_id: project.id})
      assert created_survey.schedule.start_time == ~T[01:00:00]
      assert created_survey.schedule.end_time == ~T[02:00:00]
    end

    test "rejects update with correct error when cutoff field is greater than the max value", %{
      conn: conn,
      user: user
    } do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      max_int = 2_147_483_647

      conn =
        put conn, project_survey_path(conn, :update, survey.project, survey),
          survey: Map.merge(@valid_attrs, %{cutoff: max_int})

      assert json_response(conn, 422)["errors"] == %{"cutoff" => ["must be less than #{max_int}"]}
    end

    test "rejects update with correct error when cutoff field is less than -1", %{
      conn: conn,
      user: user
    } do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      conn =
        put conn, project_survey_path(conn, :update, survey.project, survey),
          survey: Map.merge(@valid_attrs, %{cutoff: -1})

      assert json_response(conn, 422)["errors"] == %{
               "cutoff" => ["must be greater than or equal to 0"]
             }
    end

    test "updates project updated_at when survey is updated", %{conn: conn, user: user} do
      {:ok, datetime, _} = DateTime.from_iso8601("2000-01-01T00:00:00Z")
      project = create_project_for_user(user, updated_at: datetime)
      survey = insert(:survey, project: project)

      put conn, project_survey_path(conn, :update, survey.project, survey),
        survey: %{name: "New name"}

      project = Project |> Repo.get(project.id)

      # 1 -- the first date comes after the second one
      assert Timex.compare(project.updated_at, datetime) == 1
    end
  end

  describe "set_name" do
    test "set name of a survey", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      conn =
        post conn, project_survey_survey_path(conn, :set_name, project, survey), name: "new name"

      assert response(conn, 204)
      assert Repo.get(Survey, survey.id).name == "new name"
    end

    test "rejects set_name if the survey doesn't belong to the current user", %{conn: conn} do
      survey = insert(:survey)

      assert_error_sent :forbidden, fn ->
        post conn, project_survey_survey_path(conn, :set_name, survey.project, survey),
          name: "new name"
      end
    end

    test "rejects set_name for a project reader", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      survey = insert(:survey, project: project)

      assert_error_sent :forbidden, fn ->
        post conn, project_survey_survey_path(conn, :set_name, survey.project, survey),
          name: "new name"
      end
    end

    test "rejects set_name if project is archived", %{conn: conn, user: user} do
      project = create_project_for_user(user, archived: true)
      survey = insert(:survey, project: project)

      assert_error_sent :forbidden, fn ->
        post conn, project_survey_survey_path(conn, :set_name, survey.project, survey),
          name: "new name"
      end
    end
  end

  describe "set_folder_id" do
    test "set folder_id of a survey", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      folder = insert(:folder, project: project)

      conn =
        post conn, project_survey_survey_path(conn, :set_folder_id, project, survey),
          folder_id: folder.id

      assert response(conn, 204)
      assert Repo.get(Survey, survey.id).folder_id == folder.id
    end

    test "moves survey out of folder", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      folder = insert(:folder, project: project)
      survey = insert(:survey, project: project, folder: folder)

      conn =
        post conn, project_survey_survey_path(conn, :set_folder_id, project, survey),
          folder_id: nil

      assert response(conn, 204)
      assert Repo.get(Survey, survey.id).folder_id == nil
    end

    test "rejects set_folder_id if the survey belongs to a panel survey", %{
      conn: conn,
      user: user
    } do
      project = create_project_for_user(user)
      panel_survey = insert(:panel_survey, project: project)
      survey = insert(:survey, project: project, panel_survey: panel_survey)
      folder = insert(:folder, project: project)

      assert_error_sent :conflict, fn ->
        post conn, project_survey_survey_path(conn, :set_folder_id, project, survey),
          folder_id: folder.id
      end
    end

    test "rejects set_folder_id if the survey doesn't belong to the current user", %{conn: conn} do
      survey = insert(:survey)
      folder = insert(:folder)

      assert_error_sent :forbidden, fn ->
        post conn, project_survey_survey_path(conn, :set_folder_id, survey.project, survey),
          folder_id: folder.id
      end
    end

    test "rejects set_folder_id for a project reader", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      survey = insert(:survey, project: project)
      folder = insert(:folder)

      assert_error_sent :forbidden, fn ->
        post conn, project_survey_survey_path(conn, :set_folder_id, project, survey),
          folder_id: folder.id
      end
    end

    test "rejects set_folder_id if project is archived", %{conn: conn, user: user} do
      project = create_project_for_user(user, archived: true)
      survey = insert(:survey, project: project)
      folder = insert(:folder)

      assert_error_sent :forbidden, fn ->
        post conn, project_survey_survey_path(conn, :set_folder_id, project, survey),
          folder_id: folder.id
      end
    end

    test "returns 404 when the project does not exist", %{conn: conn} do
      survey = insert(:survey)
      folder = insert(:folder)

      assert_error_sent :not_found, fn ->
        post conn, project_survey_survey_path(conn, :set_folder_id, -1, survey),
          folder_id: folder.id
      end
    end

    test "returns 404 when the survey does not exist", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      folder = insert(:folder)

      assert_error_sent :not_found, fn ->
        post conn, project_survey_survey_path(conn, :set_folder_id, project, -1),
          folder_id: folder.id
      end
    end

    test "returns 404 when the folder does not exist", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      assert_error_sent :not_found, fn ->
        post conn, project_survey_survey_path(conn, :set_folder_id, project, survey),
          folder_id: -1
      end
    end

    test "returns 404 if the folder doesn't belong to the project", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      folder = insert(:folder)

      assert_error_sent :not_found, fn ->
        post conn, project_survey_survey_path(conn, :set_folder_id, project, -1),
          folder_id: folder.id
      end
    end
  end

  describe "set_description" do
    test "set description of a survey", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      conn =
        post conn, project_survey_survey_path(conn, :set_description, project, survey),
          description: "new description"

      assert response(conn, 204)
      assert Repo.get(Survey, survey.id).description == "new description"
    end

    test "rejects set_description if the survey doesn't belong to the current user", %{conn: conn} do
      survey = insert(:survey)

      assert_error_sent :forbidden, fn ->
        post conn, project_survey_survey_path(conn, :set_description, survey.project, survey),
          description: "new description"
      end
    end

    test "rejects set_description for a project reader", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      survey = insert(:survey, project: project)

      assert_error_sent :forbidden, fn ->
        post conn, project_survey_survey_path(conn, :set_description, survey.project, survey),
          description: "new description"
      end
    end

    test "rejects set_description if project is archived", %{conn: conn, user: user} do
      project = create_project_for_user(user, archived: true)
      survey = insert(:survey, project: project)

      assert_error_sent :forbidden, fn ->
        post conn, project_survey_survey_path(conn, :set_description, survey.project, survey),
          description: "new description"
      end
    end
  end

  describe "delete" do
    test "deletes chosen resource", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      conn = delete(conn, project_survey_path(conn, :delete, survey.project, survey))

      assert response(conn, 204)
      refute Repo.get(Survey, survey.id)
    end

    test "deletes the survey when it's an wave of a panel survey", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      panel_survey = insert(:panel_survey, project: project)
      insert(:survey, project: project, panel_survey: panel_survey)
      survey = insert(:survey, project: project, panel_survey: panel_survey)

      conn = delete(conn, project_survey_path(conn, :delete, survey.project, survey))

      assert response(conn, 204)
      refute Repo.get(Survey, survey.id)
    end

    test "forbids delete if the survey is the only wave of a panel survey", %{
      conn: conn,
      user: user
    } do
      project = create_project_for_user(user)
      panel_survey = insert(:panel_survey, project: project)
      survey = insert(:survey, project: project, panel_survey: panel_survey)

      assert_error_sent :conflict, fn ->
        delete(conn, project_survey_path(conn, :delete, survey.project, survey))
      end

      assert Survey |> Repo.get(survey.id)
    end

    test "forbids delete if the project doesn't belong to the current user", %{conn: conn} do
      survey = insert(:survey)

      assert_error_sent :forbidden, fn ->
        delete(conn, project_survey_path(conn, :delete, survey.project, survey))
      end
    end

    test "forbids delete for a project reader", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      survey = insert(:survey, project: project)

      assert_error_sent :forbidden, fn ->
        delete(conn, project_survey_path(conn, :delete, survey.project, survey))
      end
    end

    test "forbids delete if project is archived", %{conn: conn, user: user} do
      project = create_project_for_user(user, archived: true)
      survey = insert(:survey, project: project)

      assert_error_sent :forbidden, fn ->
        delete(conn, project_survey_path(conn, :delete, survey.project, survey))
      end
    end

    test "reject delete if the survey is running", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: :running)

      assert_error_sent :conflict, fn ->
        delete(conn, project_survey_path(conn, :delete, survey.project, survey))
      end

      assert Survey |> Repo.get(survey.id)
    end

    test "updates project updated_at when survey is deleted", %{conn: conn, user: user} do
      {:ok, datetime, _} = DateTime.from_iso8601("2000-01-01T00:00:00Z")
      project = create_project_for_user(user, updated_at: datetime)
      survey = insert(:survey, project: project)

      delete(conn, project_survey_path(conn, :delete, survey.project, survey))

      project = Project |> Repo.get(project.id)

      # 1 -- the first date comes after the second one
      assert Timex.compare(project.updated_at, datetime) == 1
    end

    test "delete survey and all contents", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      channel = insert(:channel, user: user)
      group = create_group(survey, channel)
      respondent = add_respondent_to(group)
      response = insert(:response, respondent: respondent)
      questionnaire = insert(:questionnaire, project: project)

      survey_questionnaire =
        insert(:survey_questionnaire, survey: survey, questionnaire: questionnaire)

      history = insert(:respondent_disposition_history, respondent: respondent)

      delete(conn, project_survey_path(conn, :delete, survey.project, survey))

      refute Survey |> Repo.get(survey.id)
      refute RespondentGroup |> Repo.get(group.id)
      refute Respondent |> Repo.get(respondent.id)
      refute Response |> Repo.get(response.id)
      refute SurveyQuestionnaire |> Repo.get(survey_questionnaire.id)
      refute RespondentDispositionHistory |> Repo.get(history.id)
    end
  end

  describe "changes the survey state when needed" do
    test "updates state when adding questionnaire", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)
      survey = insert(:survey, project: project, cutoff: 4, schedule: completed_schedule())
      create_group(survey, channel)

      conn =
        put conn, project_survey_path(conn, :update, project, survey),
          survey: %{questionnaire_ids: [questionnaire.id]}

      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)
      qs = (new_survey |> Repo.preload(:questionnaires)).questionnaires
      assert length(qs) == 1
      assert hd(qs).id == questionnaire.id
      assert new_survey.state == :ready
    end

    test "updates state when selecting mode", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey =
        insert(:survey,
          project: project,
          questionnaires: [questionnaire],
          cutoff: 4,
          schedule: completed_schedule()
        )

      create_group(survey, channel)

      conn =
        put conn, project_survey_path(conn, :update, project, survey), survey: %{mode: [["sms"]]}

      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)
      assert new_survey.state == :ready
    end

    test "updates state when selecting mode, missing channel", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey =
        insert(:survey,
          project: project,
          questionnaires: [questionnaire],
          cutoff: 4,
          schedule: completed_schedule()
        )

      create_group(survey, channel)

      conn =
        put conn, project_survey_path(conn, :update, project, survey),
          survey: %{mode: [["sms", "ivr"]]}

      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)
      assert new_survey.state == :not_ready
    end

    test "updates state when selecting mode, missing channel, multiple modes", %{
      conn: conn,
      user: user
    } do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey =
        insert(:survey,
          project: project,
          questionnaires: [questionnaire],
          cutoff: 4,
          schedule: completed_schedule()
        )

      create_group(survey, channel)

      conn =
        put conn, project_survey_path(conn, :update, project, survey),
          survey: %{mode: [["sms"], ["sms", "ivr"]]}

      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)
      assert new_survey.state == :not_ready
    end

    test "updates state when selecting mode, all channels", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey =
        insert(:survey,
          project: project,
          questionnaires: [questionnaire],
          cutoff: 4,
          schedule: completed_schedule()
        )

      group = create_group(survey)
      channel2 = insert(:channel, user: user, type: "ivr")
      add_channel_to(group, channel)
      add_channel_to(group, channel2)

      conn =
        put conn, project_survey_path(conn, :update, project, survey),
          survey: %{mode: [["sms", "ivr"]]}

      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)
      assert new_survey.state == :ready
    end

    test "updates state when adding cutoff", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey =
        insert(:survey,
          project: project,
          questionnaires: [questionnaire],
          schedule: completed_schedule(),
          mode: [["sms"]]
        )

      create_group(survey, channel)

      conn = put conn, project_survey_path(conn, :update, project, survey), survey: %{cutoff: 4}

      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)
      assert new_survey.state == :ready
    end

    test "changes state to not_ready when an invalid retry attempt configuration is passed", %{
      conn: conn,
      user: user
    } do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey =
        insert(:survey,
          project: project,
          cutoff: 4,
          schedule: completed_schedule(),
          mode: [["sms"]],
          questionnaires: [questionnaire]
        )

      create_group(survey, channel)

      conn =
        put conn, project_survey_path(conn, :update, project, survey),
          survey: %{sms_retry_configuration: "12j 13p 14q"}

      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)
      assert new_survey.state == :not_ready
    end

    test "changes state to not_ready when an invalid fallback delay is passed", %{
      conn: conn,
      user: user
    } do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey =
        insert(:survey,
          project: project,
          cutoff: 4,
          schedule: completed_schedule(),
          mode: [["sms"]],
          questionnaires: [questionnaire]
        )

      create_group(survey, channel)

      conn =
        put conn, project_survey_path(conn, :update, project, survey),
          survey: %{fallback_delay: "12j"}

      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)
      assert new_survey.state == :not_ready
    end

    test "returns state to ready when a valid retry configuration is passed", %{
      conn: conn,
      user: user
    } do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey =
        insert(:survey,
          project: project,
          cutoff: 4,
          schedule: completed_schedule(),
          mode: [["sms"]],
          questionnaires: [questionnaire],
          sms_retry_configuration: "12j 13p 14q"
        )

      create_group(survey, channel)
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == :not_ready

      conn =
        put conn, project_survey_path(conn, :update, project, survey),
          survey: %{sms_retry_configuration: "10m 1h 2d"}

      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)
      assert new_survey.state == :ready
    end

    test "updates state when adding a day in schedule", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey =
        insert(:survey,
          project: project,
          questionnaires: [questionnaire],
          cutoff: 3,
          mode: [["sms"]]
        )

      create_group(survey, channel)

      conn =
        put conn,
            project_survey_path(conn, :update, project, survey),
            survey: %{
              schedule: %{survey.schedule | day_of_week: %Ask.DayOfWeek{mon: true, tue: true}}
            }

      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)
      assert new_survey.state == :ready
    end

    test "updates state when removing schedule", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey =
        insert(:survey,
          project: project,
          questionnaires: [questionnaire],
          cutoff: 3,
          schedule: completed_schedule()
        )

      create_group(survey, channel)

      conn =
        put conn, project_survey_path(conn, :update, project, survey),
          survey: %{schedule: incomplete_schedule()}

      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)
      assert new_survey.state == :not_ready
    end

    test "updates state when removing questionnaire", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey =
        insert(:survey,
          project: project,
          questionnaires: [questionnaire],
          cutoff: 4,
          state: :ready,
          schedule: completed_schedule()
        )

      create_group(survey, channel)

      assert survey.state == :ready

      conn =
        put conn, project_survey_path(conn, :update, project, survey),
          survey: %{questionnaire_ids: []}

      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)
      qs = (new_survey |> Repo.preload(:questionnaires)).questionnaires
      assert length(qs) == 0
      assert new_survey.state == :not_ready
    end

    test "does not update state when adding cutoff if missing questionnaire", %{
      conn: conn,
      user: user
    } do
      [project, _, channel] = prepare_for_state_update(user)
      survey = insert(:survey, project: project, schedule: completed_schedule())

      assert survey.state == :not_ready

      create_group(survey, channel)

      conn = put conn, project_survey_path(conn, :update, project, survey), survey: %{cutoff: 4}

      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)
      assert new_survey.state == :not_ready
    end

    test "does not update state when adding cutoff if missing respondents", %{
      conn: conn,
      user: user
    } do
      [project, questionnaire, _] = prepare_for_state_update(user)

      survey =
        insert(:survey,
          project: project,
          questionnaires: [questionnaire],
          schedule: completed_schedule()
        )

      assert survey.state == :not_ready

      conn = put conn, project_survey_path(conn, :update, project, survey), survey: %{cutoff: 4}

      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)
      assert new_survey.state == :not_ready
    end

    test "does not update state when adding questionnaire if missing channel", %{
      conn: conn,
      user: user
    } do
      [project, questionnaire, _] = prepare_for_state_update(user)
      survey = insert(:survey, project: project, cutoff: 4, schedule: completed_schedule())
      group = insert(:respondent_group, survey: survey)
      add_respondent_to(group)

      conn =
        put conn, project_survey_path(conn, :update, project, survey),
          survey: %{questionnaire_id: questionnaire.id}

      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)
      assert new_survey.state == :not_ready
    end

    test "sets to not ready if comparisons' ratio don't sum 100", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey =
        insert(:survey,
          project: project,
          questionnaires: [questionnaire],
          cutoff: 3,
          schedule: completed_schedule(),
          mode: [["sms"]]
        )

      create_group(survey, channel)

      conn =
        put conn, project_survey_path(conn, :update, project, survey),
          survey: %{
            comparisons: [%{questionnaire_id: questionnaire.id, mode: ["sms"], ratio: 99}]
          }

      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)
      assert new_survey.state == :not_ready
    end

    test "sets to ready if comparisons' ratio sum 100", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey =
        insert(:survey,
          project: project,
          questionnaires: [questionnaire],
          cutoff: 3,
          schedule: completed_schedule(),
          mode: [["sms"]]
        )

      create_group(survey, channel)

      conn =
        put conn, project_survey_path(conn, :update, project, survey),
          survey: %{
            comparisons: [%{questionnaire_id: questionnaire.id, mode: ["sms"], ratio: 100}]
          }

      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)
      assert new_survey.state == :ready
    end

    test "changes state to not_ready when questionnaire is invalid", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey =
        insert(:survey,
          project: project,
          cutoff: 4,
          schedule: completed_schedule(),
          mode: [["sms"]],
          questionnaires: []
        )

      create_group(survey, channel)
      questionnaire |> Ask.Questionnaire.changeset(%{"valid" => false}) |> Repo.update!()

      conn =
        put conn, project_survey_path(conn, :update, project, survey),
          survey: %{questionnaire_ids: [questionnaire.id]}

      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)
      assert new_survey.state == :not_ready
    end

    test "changes state to not_ready when survey mode doesn't match questionnaire mode", %{
      conn: conn,
      user: user
    } do
      [project, questionnaire, channel] = prepare_for_state_update(user)
      questionnaire |> Ask.Questionnaire.changeset(%{"modes" => ["ivr"]}) |> Repo.update!()

      survey =
        insert(:survey,
          project: project,
          cutoff: 4,
          schedule: completed_schedule(),
          mode: [["ivr"]],
          questionnaires: [questionnaire]
        )

      create_group(survey, channel)

      conn =
        put conn, project_survey_path(conn, :update, project, survey), survey: %{mode: [["sms"]]}

      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)
      assert new_survey.state == :not_ready
    end
  end

  test "prevents launching a survey that is not in the ready state", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project, state: :not_ready)

    conn = post(conn, project_survey_survey_path(conn, :launch, survey.project, survey))

    assert response(conn, 422)
  end

  test "when launching a survey, it sets the state to running", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project, state: :ready)

    conn = post(conn, project_survey_survey_path(conn, :launch, survey.project, survey))

    assert json_response(conn, 200)
    assert Repo.get(Survey, survey.id).state == :running
  end

  test "when launching a survey, it creates questionnaire snapshots", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)
    questionnaire |> Ask.Questionnaire.recreate_variables!()

    survey =
      insert(:survey,
        project: project,
        state: :ready,
        questionnaires: [questionnaire],
        comparisons: [
          %{"mode" => ["sms"], "questionnaire_id" => questionnaire.id, "one" => 50},
          %{"mode" => ["sms"], "questionnaire_id" => questionnaire.id, "two" => 40}
        ]
      )

    conn = post(conn, project_survey_survey_path(conn, :launch, survey.project, survey))

    assert json_response(conn, 200)

    survey =
      Repo.get(Survey, survey.id)
      |> Repo.preload(:questionnaires)

    qs = survey.questionnaires
    assert length(qs) == 1
    q = hd(qs)
    assert q.snapshot_of == questionnaire.id
    assert q.name == questionnaire.name
    assert q.steps == questionnaire.steps
    assert q.modes == questionnaire.modes

    assert survey.comparisons == [
             %{"mode" => ["sms"], "questionnaire_id" => q.id, "one" => 50},
             %{"mode" => ["sms"], "questionnaire_id" => q.id, "two" => 40}
           ]
  end

  test "survey view contains questionnaire modes for each questionnaire after launching a survey",
       %{conn: conn, user: user} do
    project = create_project_for_user(user)

    questionnaire =
      insert(:questionnaire,
        name: "test",
        project: project,
        steps: @dummy_steps,
        modes: ["sms", "ivr"]
      )

    survey_ready =
      insert(:survey, project: project, state: :ready, questionnaires: [questionnaire])

    post(conn, project_survey_survey_path(conn, :launch, survey_ready.project, survey_ready))
    survey_launched = Repo.get(Survey, survey_ready.id)

    conn = get(conn, project_survey_path(conn, :show, project, survey_launched))

    questionnaire_snapshot_id =
      ((survey_launched |> Repo.preload(:questionnaires)).questionnaires |> hd).id
      |> Integer.to_string()

    response = json_response(conn, 200)["data"]
    assert response["questionnaires"][questionnaire_snapshot_id]["modes"] == questionnaire.modes
  end

  test "forbids launch for project reader", %{conn: conn, user: user} do
    project = create_project_for_user(user, level: "reader")
    survey = insert(:survey, project: project, state: :ready)

    assert_error_sent :forbidden, fn ->
      post(conn, project_survey_survey_path(conn, :launch, survey.project, survey))
    end
  end

  test "forbids launch if project is archived", %{conn: conn, user: user} do
    project = create_project_for_user(user, archived: true)
    survey = insert(:survey, project: project, state: :ready)

    assert_error_sent :forbidden, fn ->
      post(conn, project_survey_survey_path(conn, :launch, survey.project, survey))
    end
  end

  test "launches a survey with channel", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project, state: :ready)
    test_channel = TestChannel.new()
    channel = insert(:channel, settings: test_channel |> TestChannel.settings(), type: "sms")
    create_group(survey, channel)

    conn = post(conn, project_survey_survey_path(conn, :launch, survey.project, survey))

    assert json_response(conn, 200)
    assert Repo.get(Survey, survey.id).state == :running

    assert_received [:prepare, ^test_channel]
  end

  test "sets started_at with proper datetime value when a survey is launched", %{
    conn: conn,
    user: user
  } do
    now = Timex.now()
    project = create_project_for_user(user)
    survey = insert(:survey, project: project, state: :ready)

    post(conn, project_survey_survey_path(conn, :launch, survey.project, survey))

    started_at = Repo.get(Survey, survey.id).started_at
    assert Timex.between?(started_at, Timex.shift(now, seconds: -3), Timex.shift(now, seconds: 3))
  end

  @tag :time_mock
  test "sets last_window_ends_at with proper datetime value when a survey is launched", %{
    conn: conn,
    user: user
  } do
    project = create_project_for_user(user)
    end_date = ~D[2021-04-01]
    now = Date.add(end_date, -1)
    mock_time(Timex.to_datetime(now))
    schedule = %{completed_schedule() | end_date: end_date}
    survey = insert(:survey, project: project, state: :ready, schedule: schedule)

    post(conn, project_survey_survey_path(conn, :launch, survey.project, survey))

    last_window_ends_at = Repo.get(Survey, survey.id).last_window_ends_at

    assert DateTime.compare(last_window_ends_at, Date.add(end_date, 1) |> Timex.to_datetime()) ==
             :eq
  end

  test "updates project updated_at when a survey is launched", %{conn: conn, user: user} do
    {:ok, datetime, _} = DateTime.from_iso8601("2000-01-01T00:00:00Z")
    project = create_project_for_user(user, updated_at: datetime)
    survey = insert(:survey, project: project, state: :ready)

    post(conn, project_survey_survey_path(conn, :launch, survey.project, survey))

    project = Project |> Repo.get(project.id)

    # 1 -- the first date comes after the second one
    assert Timex.compare(project.updated_at, datetime) == 1
  end

  describe "stopping survey" do
    test "stops survey", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey = insert(:survey, project: project, state: :running)
      test_channel = TestChannel.new(false)
      channel = insert(:channel, settings: test_channel |> TestChannel.settings(), type: "sms")
      group = create_group(survey, channel)
      insert_list(10, :respondent, survey: survey, state: "pending")
      r1 = insert(:respondent, survey: survey, state: "active", respondent_group: group)
      insert_list(3, :respondent, survey: survey, state: "active", timeout_at: Timex.now())

      session = %Session{
        current_mode: SessionModeProvider.new("sms", channel, []),
        respondent: r1,
        flow: %Flow{questionnaire: questionnaire},
        schedule: survey.schedule
      }

      session = Session.dump(session)
      r1 |> Ask.Respondent.changeset(%{session: session}) |> Repo.update!()
      conn = post(conn, project_survey_survey_path(conn, :stop, survey.project, survey))
      wait_all_cancellations(conn)

      assert json_response(conn, 200)
      survey = Repo.get(Survey, survey.id)
      assert Survey.cancelled?(survey)

      assert length(
               Repo.all(
                 from(r in Ask.Respondent,
                   where: r.state == :cancelled and is_nil(r.session) and is_nil(r.timeout_at)
                 )
               )
             ) == 4

      assert_receive [:cancel_message, ^test_channel, %{}]
    end

    test "stops respondents only for the stopped survey", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey = insert(:survey, project: project, state: :running)
      survey2 = insert(:survey, project: project, state: :running)
      test_channel = TestChannel.new(false)
      channel = insert(:channel, settings: test_channel |> TestChannel.settings(), type: "sms")
      group = create_group(survey, channel)
      r1 = insert(:respondent, survey: survey, state: "active", respondent_group: group)

      insert_list(3, :respondent,
        survey: survey,
        state: "active",
        respondent_group: group,
        timeout_at: Timex.now()
      )

      insert_list(4, :respondent, survey: survey2, state: "active", session: %{})
      insert_list(2, :respondent, survey: survey2, state: "active", timeout_at: Timex.now())

      session = %Session{
        current_mode: SessionModeProvider.new("sms", channel, []),
        respondent: r1,
        flow: %Flow{questionnaire: questionnaire},
        schedule: survey.schedule
      }

      session = Session.dump(session)
      r1 |> Ask.Respondent.changeset(%{session: session}) |> Repo.update!()
      conn = post(conn, project_survey_survey_path(conn, :stop, survey.project, survey))

      wait_all_cancellations(conn)

      assert json_response(conn, 200)
      assert Repo.get(Survey, survey2.id).state == :running
      assert length(Repo.all(from(r in Ask.Respondent, where: r.state == :active))) == 6
      assert_receive [:cancel_message, ^test_channel, %{}]
    end

    test "stopping completed survey still works (#736)", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      survey =
        insert(:survey,
          project: project,
          state: "terminated",
          exit_code: 0,
          exit_message: "Successfully completed"
        )

      conn = post(conn, project_survey_survey_path(conn, :stop, survey.project, survey))

      assert json_response(conn, 200)
      survey = Repo.get(Survey, survey.id)
      assert Survey.completed?(survey)
    end

    test "stopping cancelled survey still works (#736)", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: "terminated", exit_code: 1)

      conn = post(conn, project_survey_survey_path(conn, :stop, project, survey))

      assert json_response(conn, 200)
      survey = Repo.get(Survey, survey.id)
      assert Survey.cancelled?(survey)
    end

    test "doesn't stop survey if it is locked", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: :running, locked: true)

      conn = post(conn, project_survey_survey_path(conn, :stop, project, survey))

      assert response(conn, 422)
      survey = Repo.get(Survey, survey.id)
      assert survey.state == :running
    end
  end

  describe "update locked status" do
    test "locks survey", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project)

      survey =
        insert(:survey,
          project: project,
          state: :running,
          locked: false,
          questionnaires: [questionnaire]
        )

      conn =
        put conn,
            project_survey_update_locked_status_path(
              conn,
              :update_locked_status,
              project,
              survey
            ),
            locked: true

      assert response(conn, 200)
      assert json_response(conn, 200)["data"]["locked"]
    end

    test "doesn't update locked status if user is editor", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "editor")
      questionnaire = insert(:questionnaire, project: project)

      survey =
        insert(:survey,
          project: project,
          state: :running,
          locked: false,
          questionnaires: [questionnaire]
        )

      assert_error_sent :forbidden, fn ->
        put conn,
            project_survey_update_locked_status_path(
              conn,
              :update_locked_status,
              project,
              survey
            ),
            locked: true
      end
    end

    test "doesn't update locked status if parameter is invalid", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project)

      survey =
        insert(:survey,
          project: project,
          state: :running,
          locked: false,
          questionnaires: [questionnaire]
        )

      conn =
        put conn,
            project_survey_update_locked_status_path(
              conn,
              :update_locked_status,
              project,
              survey
            ),
            locked: "foo"

      survey = Repo.get(Survey, survey.id)

      assert response(conn, 422)
      assert not survey.locked
    end

    test "doesn't update locked status if survey state is not running", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project)

      [:not_ready, :ready, :pending, :terminated]
      |> Enum.each(fn state ->
        survey =
          insert(:survey,
            project: project,
            state: state,
            locked: false,
            questionnaires: [questionnaire]
          )

        conn =
          put conn,
              project_survey_update_locked_status_path(
                conn,
                :update_locked_status,
                project,
                survey
              ),
              locked: true

        survey = Repo.get(Survey, survey.id)

        assert response(conn, 422)
        assert not survey.locked
      end)
    end
  end

  describe "config" do
    setup context do
      project = create_project_for_user(context[:user])
      survey = insert(:survey, project: project)
      [project: project, survey: survey]
    end

    test "post", %{conn: conn, project: project, survey: survey} do
      post(conn, project_survey_survey_path(conn, :config, project, survey))
    end

    test "get", %{conn: conn, project: project, survey: survey} do
      get(conn, project_survey_survey_path(conn, :config, project, survey))
    end
  end

  describe "activity logs" do
    setup %{conn: conn} do
      remote_ip = {192, 168, 0, 128}
      conn = %{conn | remote_ip: remote_ip}
      {:ok, conn: conn, remote_ip: remote_ip}
    end

    test "generates log after creating a survey", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      post(conn, project_survey_path(conn, :create, project.id))

      log = ActivityLog |> Repo.one()
      survey = Survey |> Repo.one()

      assert_survey_log(%{
        log: log,
        user: user,
        project: project,
        survey: survey,
        action: "create",
        remote_ip: "192.168.0.128",
        metadata: nil
      })
    end

    test "generates log after deleting a survey", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      delete(conn, project_survey_path(conn, :delete, survey.project, survey))
      log = ActivityLog |> Repo.one()

      assert_survey_log(%{
        log: log,
        user: user,
        project: project,
        survey: survey,
        action: "delete",
        remote_ip: "192.168.0.128",
        metadata: %{"survey_name" => survey.name}
      })
    end

    test "generates log after launching a survey", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: :ready)

      post(conn, project_survey_survey_path(conn, :launch, survey.project, survey))
      log = ActivityLog |> Repo.one()

      assert_survey_log(%{
        log: log,
        user: user,
        project: project,
        survey: survey,
        action: "start",
        remote_ip: "192.168.0.128",
        metadata: %{"survey_name" => survey.name}
      })
    end

    test "generates logs after stopping a survey", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: :running)

      post(conn, project_survey_survey_path(conn, :stop, survey.project, survey))

      # FIXME: flaky test: sometimes Repo.all will only return 1 row
      Process.sleep(100)
      logs = Repo.all(ActivityLog)

      assert_survey_log(%{
        log: Enum.at(logs, 0),
        user_id: user.id,
        project: project,
        survey: survey,
        action: "request_cancel",
        remote_ip: "192.168.0.128",
        metadata: %{"survey_name" => survey.name}
      })

      assert_survey_log(%{
        log: Enum.at(logs, 1),
        user_id: nil,
        project: project,
        survey: survey,
        action: "completed_cancel",
        remote_ip: "0.0.0.0",
        metadata: %{"survey_name" => survey.name}
      })
    end

    test "generates log after updating a survey", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      put conn, project_survey_path(conn, :update, project, survey), survey: %{cutoff: 30}
      log = ActivityLog |> Repo.one()

      assert_survey_log(%{
        log: log,
        user: user,
        project: project,
        survey: survey,
        action: "edit",
        remote_ip: "192.168.0.128",
        metadata: %{"survey_name" => survey.name}
      })
    end

    test "generates rename log if name changed", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      put conn, project_survey_path(conn, :update, project, survey),
        survey: %{name: "new name", quotas: %{vars: [], buckets: []}, questionnaires: []}

      log = ActivityLog |> Repo.one()

      assert_survey_log(%{
        log: log,
        user: user,
        project: project,
        survey: survey,
        action: "rename",
        remote_ip: "192.168.0.128",
        metadata: %{"old_survey_name" => survey.name, "new_survey_name" => "new name"}
      })
    end

    test "generates both rename and edit log if name and another property changes", %{
      conn: conn,
      user: user
    } do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      put conn, project_survey_path(conn, :update, project, survey),
        survey: %{cutoff: 30, name: "new name"}

      rename_log = ActivityLog |> where([log], log.action == "rename") |> Repo.one()
      edit_log = ActivityLog |> where([log], log.action == "edit") |> Repo.one()

      assert_survey_log(%{
        log: rename_log,
        user: user,
        project: project,
        survey: survey,
        action: "rename",
        remote_ip: "192.168.0.128",
        metadata: %{"old_survey_name" => survey.name, "new_survey_name" => "new name"}
      })

      assert_survey_log(%{
        log: edit_log,
        user: user,
        project: project,
        survey: survey,
        action: "edit",
        remote_ip: "192.168.0.128",
        metadata: %{"survey_name" => survey.name}
      })
    end

    test "generates rename log with set_name action", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      post conn, project_survey_survey_path(conn, :set_name, project, survey), name: "new name"
      log = ActivityLog |> Repo.one!()

      assert_survey_log(%{
        log: log,
        user: user,
        project: project,
        survey: survey,
        action: "rename",
        remote_ip: "192.168.0.128",
        metadata: %{"old_survey_name" => survey.name, "new_survey_name" => "new name"}
      })
    end

    test "generates change_description log with set_description action", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)

      post conn, project_survey_survey_path(conn, :set_description, project, survey),
        description: "new description"

      log = ActivityLog |> Repo.one!()

      assert_survey_log(%{
        log: log,
        user: user,
        project: project,
        survey: survey,
        action: "change_description",
        remote_ip: "192.168.0.128",
        metadata: %{
          "old_survey_description" => survey.description,
          "new_survey_description" => "new description",
          "survey_name" => survey.name
        }
      })
    end

    test "generates lock log", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project)

      survey =
        insert(:survey,
          project: project,
          state: :running,
          locked: false,
          questionnaires: [questionnaire]
        )

      put conn,
          project_survey_update_locked_status_path(conn, :update_locked_status, project, survey),
          locked: true

      log = ActivityLog |> Repo.one!()

      assert_survey_log(%{
        log: log,
        user: user,
        project: project,
        survey: survey,
        action: "lock",
        remote_ip: "192.168.0.128",
        metadata: %{"survey_name" => survey.name}
      })
    end

    test "generates unlock log", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project)

      survey =
        insert(:survey,
          project: project,
          state: :running,
          locked: true,
          questionnaires: [questionnaire]
        )

      put conn,
          project_survey_update_locked_status_path(conn, :update_locked_status, project, survey),
          locked: false

      log = ActivityLog |> Repo.one!()

      assert_survey_log(%{
        log: log,
        user: user,
        project: project,
        survey: survey,
        action: "unlock",
        remote_ip: "192.168.0.128",
        metadata: %{"survey_name" => survey.name}
      })
    end
  end

  describe "panel surveys" do
    setup %{user: user} do
      project = create_project_for_user(user)
      %{project: project}
    end

    test "shows a survey that belongs to a panel survey", %{conn: conn, project: project} do
      panel_survey = insert(:panel_survey, project: project)
      survey = insert(:survey, project: project, panel_survey: panel_survey)

      conn = get(conn, project_survey_path(conn, :show, project, survey))

      assert json_response(conn, 200)["data"]["panel_survey_id"] == panel_survey.id
    end

    test "shows a regular survey", %{conn: conn, project: project} do
      survey = insert(:survey, project: project)

      conn = get(conn, project_survey_path(conn, :show, project, survey))

      assert json_response(conn, 200)["data"]["panel_survey_id"] == nil
    end
  end

  def prepare_for_state_update(user) do
    project = create_project_for_user(user)
    questionnaire = insert(:questionnaire, name: "test", project: project)
    channel = insert(:channel, name: "test")
    [project, questionnaire, channel]
  end

  defp add_respondent_to(group = %RespondentGroup{}) do
    insert(:respondent, phone_number: "12345678", survey: group.survey, respondent_group: group)
  end

  def completed_schedule() do
    Ask.Schedule.always()
  end

  def incomplete_schedule() do
    Ask.Schedule.default()
  end

  defp add_channel_to(group = %RespondentGroup{}, channel = %Channel{}) do
    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{
      respondent_group_id: group.id,
      channel_id: channel.id,
      mode: channel.type
    })
    |> Repo.insert()
  end

  defp create_group(survey, channel \\ nil) do
    group = insert(:respondent_group, survey: survey, respondents_count: 1)

    if channel do
      add_channel_to(group, channel)
    end

    add_respondent_to(group)
    group
  end

  defp assert_log(log, user_id, project, survey, action, remote_ip) do
    assert log.project_id == project.id
    assert log.user_id == user_id
    assert log.entity_id == survey.id
    assert log.entity_type == "survey"
    assert log.action == action
    assert log.remote_ip == remote_ip
  end

  defp assert_survey_log(%{
         log: log,
         user: user,
         project: project,
         survey: survey,
         action: action,
         remote_ip: remote_ip,
         metadata: metadata
       }) do
    assert_survey_log(%{
      log: log,
      user_id: user.id,
      project: project,
      survey: survey,
      action: action,
      remote_ip: remote_ip,
      metadata: metadata
    })
  end

  defp assert_survey_log(%{
         log: log,
         user_id: user_id,
         project: project,
         survey: survey,
         action: action,
         remote_ip: remote_ip,
         metadata: metadata
       }) do
    assert_log(log, user_id, project, survey, action, remote_ip)
    assert log.metadata == metadata
  end

  def wait_all_cancellations(conn) do
    conn.assigns[:processors_pids]
    |> Enum.map(&Process.monitor/1)
    |> Enum.each(&receive_down/1)
  end

  def receive_down(ref) do
    receive do
      {:DOWN, ^ref, _, _, _} -> :task_is_down
    end
  end
end
