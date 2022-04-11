defmodule AskWeb.SurveyCancellerTest do
  use AskWeb.ConnCase
  use Ask.TestHelpers
  use Ask.DummySteps

  alias Ask.{Survey, RespondentGroup, Channel, TestChannel, RespondentGroupChannel}
  alias Ask.Runtime.{Flow, Session}
  alias Ask.Runtime.SessionModeProvider

  setup %{conn: conn} do
    user = insert(:user)

    conn =
      conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn, user: user}
  end

  describe "stops surveys as if the application were starting" do
    test "survey canceller does not have pending surveys to cancel" do
      survey_canceller = Ask.SurveyCanceller.start_cancelling(nil)
      assert survey_canceller == :ignore

      assert length(
               Repo.all(
                 from(
                   r in Ask.Respondent,
                   where: r.state == :cancelled and is_nil(r.session) and is_nil(r.timeout_at)
                 )
               )
             ) == 0
    end

    test "stops a survey in cancelling status without its id", %{user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey_1 = insert(:survey, project: project, state: "cancelling")
      test_channel = TestChannel.new(false)

      channel =
        insert(
          :channel,
          settings:
            test_channel
            |> TestChannel.settings(),
          type: "sms"
        )

      group = create_group(survey_1, channel)
      r1 = insert(:respondent, survey: survey_1, state: "active", respondent_group: group)
      insert_list(3, :respondent, survey: survey_1, state: "active", timeout_at: Timex.now())
      channel_state = %{"call_id" => 123}

      session = %Session{
        current_mode: SessionModeProvider.new("sms", channel, []),
        channel_state: channel_state,
        respondent: r1,
        flow: %Flow{
          questionnaire: questionnaire
        },
        schedule: survey_1.schedule
      }

      session = Session.dump(session)

      r1
      |> Ask.Respondent.changeset(%{session: session})
      |> Repo.update!()

      survey_canceller = Ask.SurveyCanceller.start_cancelling(nil)

      assert %Ask.SurveyCanceller{processes: _, consumers_pids: _} = survey_canceller

      wait_all_cancellations_from_pids(survey_canceller.processes)

      survey = Repo.get(Survey, survey_1.id)
      assert Survey.cancelled?(survey)

      assert length(
               Repo.all(
                 from(
                   r in Ask.Respondent,
                   where: r.state == :cancelled and is_nil(r.session) and is_nil(r.timeout_at)
                 )
               )
             ) == 4

      assert_receive [:cancel_message, ^test_channel, ^channel_state]
    end

    test "stops multiple survey in cancelling status", %{user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey_1 = insert(:survey, project: project, state: "cancelling")
      survey_2 = insert(:survey, project: project, state: "cancelling")
      test_channel = TestChannel.new(false)

      channel =
        insert(
          :channel,
          settings:
            test_channel
            |> TestChannel.settings(),
          type: "sms"
        )

      group = create_group(survey_1, channel)
      r1 = insert(:respondent, survey: survey_1, state: "active", respondent_group: group)
      insert_list(3, :respondent, survey: survey_1, state: "active", timeout_at: Timex.now())
      insert_list(3, :respondent, survey: survey_2, state: "active", timeout_at: Timex.now())
      channel_state = %{"call_id" => 123}

      session = %Session{
        current_mode: SessionModeProvider.new("sms", channel, []),
        channel_state: channel_state,
        respondent: r1,
        flow: %Flow{
          questionnaire: questionnaire
        },
        schedule: survey_1.schedule
      }

      session = Session.dump(session)

      r1
      |> Ask.Respondent.changeset(%{session: session})
      |> Repo.update!()

      survey_canceller = Ask.SurveyCanceller.start_cancelling(nil)

      assert %Ask.SurveyCanceller{processes: _, consumers_pids: _} = survey_canceller

      wait_all_cancellations_from_pids(survey_canceller.processes)

      survey = Repo.get(Survey, survey_1.id)
      survey_2 = Repo.get(Survey, survey_2.id)
      assert Survey.cancelled?(survey)
      assert Survey.cancelled?(survey_2)

      assert length(
               Repo.all(
                 from(
                   r in Ask.Respondent,
                   where: r.state == :cancelled and is_nil(r.session) and is_nil(r.timeout_at)
                 )
               )
             ) == 7

      assert_receive [:cancel_message, ^test_channel, ^channel_state]
    end

    test "stops multiple surveys from canceller and from controller simultaneously", %{
      conn: conn,
      user: user
    } do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey_1 = insert(:survey, project: project, state: "cancelling")
      survey_2 = insert(:survey, project: project, state: "cancelling")
      survey_3 = insert(:survey, project: project, state: "running")
      test_channel = TestChannel.new(false)

      channel =
        insert(
          :channel,
          settings:
            test_channel
            |> TestChannel.settings(),
          type: "sms"
        )

      group_1 = create_group(survey_1, channel)
      r1 = insert(:respondent, survey: survey_1, state: "active", respondent_group: group_1)
      insert_list(3, :respondent, survey: survey_1, state: "active", timeout_at: Timex.now())
      insert_list(4, :respondent, survey: survey_2, state: "active", timeout_at: Timex.now())
      insert_list(3, :respondent, survey: survey_3, state: "active", timeout_at: Timex.now())
      channel_state = %{"call_id" => 123}

      session = %Session{
        current_mode: SessionModeProvider.new("sms", channel, []),
        channel_state: channel_state,
        respondent: r1,
        flow: %Flow{
          questionnaire: questionnaire
        },
        schedule: survey_1.schedule
      }

      session = Session.dump(session)

      r1
      |> Ask.Respondent.changeset(%{session: session})
      |> Repo.update!()

      survey_canceller = Ask.SurveyCanceller.start_cancelling(nil)
      conn = post(conn, project_survey_survey_path(conn, :stop, survey_3.project, survey_3))

      assert %Ask.SurveyCanceller{processes: _, consumers_pids: _} = survey_canceller

      wait_all_cancellations_from_conn(conn)
      wait_all_cancellations_from_pids(survey_canceller.processes)

      survey = Repo.get(Survey, survey_1.id)
      survey_2 = Repo.get(Survey, survey_2.id)
      survey_3 = Repo.get(Survey, survey_3.id)
      assert Survey.cancelled?(survey)
      assert Survey.cancelled?(survey_2)
      assert Survey.cancelled?(survey_3)

      assert length(
               Repo.all(
                 from(
                   r in Ask.Respondent,
                   where: r.state == :cancelled and is_nil(r.session) and is_nil(r.timeout_at)
                 )
               )
             ) == 11

      assert_receive [:cancel_message, ^test_channel, ^channel_state]
    end

    defp create_group(survey, channel) do
      group = insert(:respondent_group, survey: survey, respondents_count: 1)

      if channel do
        add_channel_to(group, channel)
      end

      add_respondent_to(group)
      group
    end

    defp add_respondent_to(group = %RespondentGroup{}) do
      insert(:respondent, phone_number: "12345678", survey: group.survey, respondent_group: group)
    end

    defp add_channel_to(group = %RespondentGroup{}, channel = %Channel{}) do
      RespondentGroupChannel.changeset(
        %RespondentGroupChannel{},
        %{respondent_group_id: group.id, channel_id: channel.id, mode: channel.type}
      )
      |> Repo.insert()
    end

    def wait_all_cancellations_from_pids(pids) do
      pids
      |> Enum.map(fn {_, pid} -> Process.monitor(pid) end)
      |> Enum.each(&receive_down/1)
    end

    def wait_all_cancellations_from_conn(conn) do
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
end
