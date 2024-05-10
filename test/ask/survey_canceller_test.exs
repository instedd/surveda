# FIXME: no test here directly references the SurveyCanceller. So maybe
# this is a SurveyCancellerSupervisor test, or a mixture between
# supervisor and controller
defmodule Ask.SurveyCancellerTest do
  use AskWeb.ConnCase
  use Ask.TestHelpers
  use Ask.DummySteps

  alias Ask.{Survey, RespondentGroup, Channel, TestChannel, RespondentGroupChannel}
  alias Ask.Runtime.{Flow, Session, SurveyCancellerSupervisor}
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
      assert [] = simulate_survey_canceller_start()

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
      survey_1 = cancelling_survey(project)
      test_channel = TestChannel.new(false)

      channel =
        insert(:channel,
          settings:
            test_channel
            |> TestChannel.settings(),
          type: "sms"
        )

      group = create_group(survey_1, channel)
      r1 = insert(:respondent, survey: survey_1, state: "active", respondent_group: group)
      insert_list(3, :respondent, survey: survey_1, state: "active", timeout_at: Timex.now())

      session = %Session{
        current_mode: SessionModeProvider.new("sms", channel, []),
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

      simulate_survey_canceller_start()

      wait_all_cancellations(survey_1)

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

      assert_receive [:cancel_message, ^test_channel, %{}]
    end

    test "stops multiple survey in cancelling status", %{user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey_1 = cancelling_survey(project)
      survey_2 = cancelling_survey(project)
      test_channel = TestChannel.new(false)

      channel =
        insert(:channel,
          settings:
            test_channel
            |> TestChannel.settings(),
          type: "sms"
        )

      group = create_group(survey_1, channel)
      r1 = insert(:respondent, survey: survey_1, state: "active", respondent_group: group)
      insert_list(3, :respondent, survey: survey_1, state: "active", timeout_at: Timex.now())
      insert_list(3, :respondent, survey: survey_2, state: "active", timeout_at: Timex.now())

      session = %Session{
        current_mode: SessionModeProvider.new("sms", channel, []),
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

      simulate_survey_canceller_start()

      wait_all_cancellations(survey_1)
      wait_all_cancellations(survey_2)

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

      assert_receive [:cancel_message, ^test_channel, %{}]
    end

    test "stops multiple surveys from canceller and from controller simultaneously", %{
      conn: conn,
      user: user
    } do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey_1 = cancelling_survey(project)
      survey_2 = cancelling_survey(project)
      survey_3 = insert(:survey, project: project, state: :running)
      test_channel = TestChannel.new(false)

      channel =
        insert(:channel,
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

      session = %Session{
        current_mode: SessionModeProvider.new("sms", channel, []),
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

      simulate_survey_canceller_start()
      post(conn, project_survey_survey_path(conn, :stop, survey_3.project, survey_3))

      wait_all_cancellations(survey_1)
      wait_all_cancellations(survey_2)
      wait_all_cancellations(survey_3)

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

      assert_receive [:cancel_message, ^test_channel, %{}]
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
  end

  describe "failure resistance" do
    test "keeps cancelling other respondents when cancelling some fail", %{user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      survey = cancelling_survey(project)
      test_channel = TestChannel.new(false)

      channel =
        insert(:channel,
          settings:
            test_channel
            |> TestChannel.settings(),
          type: "sms"
        )

      respondent_group = create_group(survey, channel)
      insert_list(5, :respondent, survey: survey, state: "active", respondent_group: respondent_group)

      failing_respondent = insert(:respondent, survey: survey, state: "active", respondent_group: respondent_group)
      failing_session = %Session{
        current_mode: nil, # this will make the canceller fail
        respondent: failing_respondent,
        flow: %Flow{
          questionnaire: questionnaire
        },
        schedule: survey.schedule
      }

      failing_respondent
      |> Ask.Respondent.changeset(%{session: Session.dump(failing_session)})
      |> Repo.update!()

      insert_list(5, :respondent, survey: survey, state: "active", respondent_group: respondent_group)

      simulate_survey_canceller_start()

      wait_for_cancels(survey, 3)

      survey = Repo.get(Survey, survey.id)
      refute Survey.cancelled?(survey)

      assert length(
               Repo.all(
                 from(
                   r in Ask.Respondent,
                   where: r.state == :cancelled and is_nil(r.session) and is_nil(r.timeout_at)
                 )
               )
             ) == 10
      assert Repo.get(Respondent, failing_respondent.id).state == :active
    end
  end

  defp wait_for_cancels(%Survey{id: survey_id}, times) do
    canceller = SurveyCancellerSupervisor.canceller_pid(survey_id)
    :erlang.trace(canceller, true, [:receive])
    wait_for_cancels(canceller, times)
  end

  defp wait_for_cancels(_pid, 0), do: true
  defp wait_for_cancels(canceller_pid, times) do
    assert_receive {:trace, ^canceller_pid, :receive, :cancel}, 2_000
    wait_for_cancels(canceller_pid, times - 1)
  end

  defp wait_all_cancellations(%{id: survey_id}) do
    ref =
      SurveyCancellerSupervisor.canceller_pid(survey_id)
      |> Process.monitor()

    receive do
      {:DOWN, ^ref, _, _, _reason} -> :task_is_down
    end
  end

  defp simulate_survey_canceller_start() do
    # The SurveyCancellerSupervisor is started by mix before running the tests, so calling
    # `start_link` would error with :already_started
    # Instead, here we call `init` to check which cancellers should start, and then we start
    # said cancellers
    {:ok, {_, cancellers_to_run}} = SurveyCancellerSupervisor.init(nil)

    cancellers_to_run
    |> Enum.each(fn %{start: {Ask.Runtime.SurveyCanceller, :start_link, [survey_id]}} ->
      SurveyCancellerSupervisor.start_cancelling(survey_id)
    end)

    cancellers_to_run
  end

  defp cancelling_survey(project) do
    insert(:survey, project: project, state: "cancelling", exit_code: 1)
  end
end
