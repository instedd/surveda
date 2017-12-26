defmodule Ask.SessionTest do
  use Ask.ModelCase
  use Ask.DummySteps
  import Ask.Factory
  alias Ask.Runtime.Session
  alias Ask.Runtime.SessionModeProvider
  alias Ask.TestChannel
  alias Ask.Runtime.{Flow, Reply, ReplyHelper}
  alias Ask.{Survey, Respondent, QuotaBucket, Questionnaire, Schedule}
  require Ask.Runtime.ReplyHelper

  setup do
    quiz = insert(:questionnaire, steps: @dummy_steps)
    |> Questionnaire.changeset(%{settings: %{"thank_you_message" => nil} })
    |> Repo.update!

    respondent = insert(:respondent)
    test_channel = TestChannel.new
    channel = insert(:channel, settings: test_channel |> TestChannel.settings)
    {:ok, quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel}
  end

  test "session load should default to Schedule.always when nil (for sessions created before the schedule was added there)", %{quiz: quiz, respondent: respondent, channel: channel} do
    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms", Schedule.default)

    session = session
      |> Session.dump

    session = %{session | schedule: nil}
      |> Poison.encode!
      |> Poison.decode!
      |> Session.load

    assert session.schedule == Schedule.always
  end

  test "start", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    {:ok, session, _, timeout, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always())
    assert %Session{token: token} = session
    assert 10 = timeout
    assert token != nil

    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]
  end

  test "start with web mode", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    {:ok, session, _, timeout, _} = Session.start(quiz, respondent, channel, "mobileweb", Schedule.always())
    assert %Session{token: token} = session
    assert 10 = timeout
    assert token != nil

    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Contact", message)]
    assert message == "Please enter http://app.ask.dev/mobile_survey/#{respondent.id}?token=#{Respondent.token(respondent.id)}"
  end

  test "reloading the page should not consume retries in mobileweb mode", %{respondent: respondent, test_channel: test_channel, channel: channel} do
    quiz = insert(:questionnaire, steps: @mobileweb_dummy_steps)
    retries = [1, 2, 3]

    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "mobileweb", Schedule.always(), retries)
    assert %Session{token: token} = session
    assert token != nil

    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Contact", message)]
    assert message == "Please enter http://app.ask.dev/mobile_survey/#{respondent.id}?token=#{Respondent.token(respondent.id)}"

    assert {:ok, %Session{current_mode: %{retries: ^retries}} = session, ReplyHelper.simple("Let there be rock", "Welcome to the survey!"), _, _} = Session.sync_step(session, Flow.Message.answer())
    assert {:ok, %Session{current_mode: %{retries: ^retries}} = session, ReplyHelper.simple("Let there be rock", "Welcome to the survey!"), _, _} = Session.sync_step(session, Flow.Message.answer())
    assert {:ok, %Session{current_mode: %{retries: ^retries}} = session, ReplyHelper.simple("Let there be rock", "Welcome to the survey!"), _, _} = Session.sync_step(session, Flow.Message.answer())

    step_result = Session.sync_step(session, Flow.Message.reply(""))
    assert {:ok, session, ReplyHelper.simple("Do you smoke?", "Do you smoke?"), _, _} = step_result

    assert {:ok, %Session{current_mode: %{retries: ^retries}} = session, ReplyHelper.simple("Do you smoke?", "Do you smoke?"), _, _} = Session.sync_step(session, Flow.Message.answer())
    assert {:ok, %Session{current_mode: %{retries: ^retries}} = session, ReplyHelper.simple("Do you smoke?", "Do you smoke?"), _, _} = Session.sync_step(session, Flow.Message.answer())
    assert {:ok, %Session{current_mode: %{retries: ^retries}} = session, ReplyHelper.simple("Do you smoke?", "Do you smoke?"), _, _} = Session.sync_step(session, Flow.Message.answer())

    expected_session = %Session{
      current_mode: SessionModeProvider.new("mobileweb", channel, retries),
      fallback_mode: nil,
      flow: %Flow{questionnaire: quiz, mode: "mobileweb", current_step: 1}
    }

    assert session.current_mode == expected_session.current_mode
    assert session.fallback_mode == expected_session.fallback_mode
    assert session.flow.questionnaire == expected_session.flow.questionnaire
    assert session.flow.mode == expected_session.flow.mode
    assert session.flow.current_step == expected_session.flow.current_step

    step_result = Session.sync_step(session, Flow.Message.reply("No"))
    assert {:ok, session, ReplyHelper.simple("Do you exercise", "Do you exercise?", %{"Smokes" => "No"}), _, _} = step_result

    assert {:ok, %Session{current_mode: %{retries: ^retries}} = session, ReplyHelper.simple("Do you exercise", "Do you exercise?"), _, _} = Session.sync_step(session, Flow.Message.answer())
    assert {:ok, %Session{current_mode: %{retries: ^retries}} = session, ReplyHelper.simple("Do you exercise", "Do you exercise?"), _, _} = Session.sync_step(session, Flow.Message.answer())
    assert {:ok, %Session{current_mode: %{retries: ^retries}} = session, ReplyHelper.simple("Do you exercise", "Do you exercise?"), _, _} = Session.sync_step(session, Flow.Message.answer())

    expected_session = %Session{
      current_mode: SessionModeProvider.new("mobileweb", channel, retries),
      fallback_mode: nil,
      flow: %Flow{questionnaire: quiz, mode: "mobileweb", current_step: 3}
    }

    assert session.current_mode == expected_session.current_mode
    assert session.fallback_mode == expected_session.fallback_mode
    assert session.flow.questionnaire == expected_session.flow.questionnaire
    assert session.flow.mode == expected_session.flow.mode
    assert session.flow.current_step == expected_session.flow.current_step
  end

  test "start with fallback delay", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    {:ok, session, _, timeout, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always(), [], nil, nil, nil, 123)
    assert %Session{token: token} = session
    assert 123 = timeout
    assert token != nil

    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]
  end

  test "start with channel without push", %{quiz: quiz, respondent: respondent} do
    test_channel = TestChannel.new
    channel = build(:channel, settings: test_channel |> TestChannel.settings)

    {:ok, session, _, timeout, _} = Session.start(quiz, respondent, channel, "ivr", Schedule.always())

    assert %Session{token: token} = session
    assert 10 = timeout
    assert token != nil

    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    refute_receive _

    assert session.channel_state == 0
  end

  test "retry question", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    assert {:ok, session = %Session{token: token}, _, 5, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always(), [5])
    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    assert {:ok, session = %Session{token: token2}, _, 10, _} = Session.timeout(session)
    assert token2 != token
    assert_receive [:ask, ^test_channel, ^respondent, ^token2, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    assert {:stalled, _, _} = Session.timeout(session)
  end

  test "retry with IVR channel", %{quiz: quiz, respondent: respondent} do
    test_channel = TestChannel.new
    channel = build(:channel, settings: test_channel |> TestChannel.settings)

    {:ok, session = %Session{token: token}, _, 5, _} = Session.start(quiz, respondent, channel, "ivr", Schedule.always(), [5])
    assert_receive [:setup, ^test_channel, ^respondent, ^token]

    assert {:ok, %Session{token: token2}, _, 10, _} = Session.timeout(session)
    assert token2 != token
    assert_receive [:setup, ^test_channel, ^respondent, ^token2]
  end

  test "last retry", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    {:ok, session = %Session{token: token}, _, 10, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always())
    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    assert {:stalled, _, _} = Session.timeout(session)
  end

  test "doesn't retry if has queued message" do
    quiz = insert(:questionnaire, steps: @dummy_steps)
    respondent = insert(:respondent)
    test_channel = TestChannel.new(true)
    channel = build(:channel, settings: test_channel |> TestChannel.settings)

    assert {:ok, session = %Session{token: token}, _, 5, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always(), [5])
    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    assert {:ok, ^session, %Reply{}, 5, _} = Session.timeout(session)
  end

  test "doesn't fail if it has a queued message" do
    quiz = insert(:questionnaire, steps: @dummy_steps)
    respondent = insert(:respondent)
    test_channel = TestChannel.new(true)
    channel = build(:channel, settings: test_channel |> TestChannel.settings)

    assert {:ok, session = %Session{token: token}, _, 10, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always())
    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    assert {:ok, ^session, %Reply{}, 10, _} = Session.timeout(session)
  end

  test "mark respondent as failed when failure notification arrives on last retry", %{quiz: quiz, respondent: respondent, channel: channel} do
    {:ok, session = %Session{}, _, 10, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always())
    assert :failed = Session.channel_failed(session, 'failed')
  end

  test "ignore failure notification when channel fails but there are retries", %{quiz: quiz, respondent: respondent, channel: channel} do
    {:ok, session = %Session{}, _, 5, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always(), [5])
    assert :ok = Session.channel_failed(session, 'failed')
  end

  test "ignore failure notification when channel fails but there is a fallback channel", %{quiz: quiz, respondent: respondent, channel: channel} do
    {:ok, session = %Session{}, _, 10, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always(), [], channel, "sms")
    assert :ok = Session.channel_failed(session, 'failed')
  end

  # Primary SMS fallbacks to IVR
  test "switch to fallback after last retry", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    fallback_runtime_channel = TestChannel.new
    fallback_channel = build(:channel, settings: fallback_runtime_channel |> TestChannel.settings, type: "ivr")
    fallback_retries = [5]

    {:ok, session = %Session{token: token}, _, 10, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always(), [], fallback_channel, "ivr", fallback_retries)
    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    expected_session = %Session{
      current_mode: SessionModeProvider.new("ivr", fallback_channel, fallback_retries),
      fallback_mode: nil,
      flow: %Flow{questionnaire: quiz, mode: fallback_channel.type, current_step: session.flow.current_step}
    }

    {:ok, result = %Session{token: token}, _, 5, _} = Session.timeout(session)
    assert_receive [:setup, ^fallback_runtime_channel, ^respondent, ^token]

    assert result.current_mode == expected_session.current_mode
    assert result.fallback_mode == expected_session.fallback_mode
    assert result.flow.questionnaire == expected_session.flow.questionnaire
    assert result.flow.mode == expected_session.flow.mode
    assert result.flow.current_step == expected_session.flow.current_step
  end

  # Primary SMS retries SMS and then fallbacks to IVR
  test "switch to fallback after specified time", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    fallback_runtime_channel = TestChannel.new
    fallback_channel = build(:channel, settings: fallback_runtime_channel |> TestChannel.settings, type: "ivr")
    fallback_retries = [7]

    {:ok, session = %Session{token: token}, _, 2, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always(), [2], fallback_channel, "ivr", fallback_retries)
    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    expected_session = %Session{
      current_mode: SessionModeProvider.new("ivr", fallback_channel, fallback_retries),
      fallback_mode: nil,
      flow: %Flow{questionnaire: quiz, mode: fallback_channel.type, current_step: session.flow.current_step}
    }

    {_, session_after_retry, _, _, _} = Session.timeout(session)
    {:ok, result = %Session{token: token}, _, 7, _} = Session.timeout(session_after_retry)
    assert_receive [:setup, ^fallback_runtime_channel, ^respondent, ^token]

    assert result.current_mode == expected_session.current_mode
    assert result.fallback_mode == expected_session.fallback_mode
    assert result.flow.questionnaire == expected_session.flow.questionnaire
    assert result.flow.mode == expected_session.flow.mode
    assert result.flow.current_step == expected_session.flow.current_step
  end

  # Primary SMS retries SMS and then fallbacks to IVR
  test "switch to fallback after retrying twice", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    fallback_runtime_channel = TestChannel.new
    fallback_channel = build(:channel, settings: fallback_runtime_channel |> TestChannel.settings, type: "ivr")
    fallback_retries = [5]

    {:ok, session = %Session{token: token}, _, 2, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always(), [2, 3], fallback_channel, "ivr", fallback_retries)
    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    expected_session = %Session{
      current_mode: SessionModeProvider.new("ivr", fallback_channel, fallback_retries),
      fallback_mode: nil,
      flow: %Flow{questionnaire: quiz, mode: fallback_channel.type, current_step: session.flow.current_step}
    }

    {:ok, session = %Session{token: token}, _, 3, _} = Session.timeout(session)
    refute_receive [:setup, _, _, _, _]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    {_, session_after_second_retry, _, _, _} = Session.timeout(session)
    {:ok, result = %Session{token: token}, _, 5, _} = Session.timeout(session_after_second_retry)
    assert_receive [:setup, ^fallback_runtime_channel, ^respondent, ^token]

    assert result.current_mode == expected_session.current_mode
    assert result.fallback_mode == expected_session.fallback_mode
    assert result.flow.questionnaire == expected_session.flow.questionnaire
    assert result.flow.mode == expected_session.flow.mode
    assert result.flow.current_step == expected_session.flow.current_step
  end

  test "doesn't switch to fallback if there are queued messages", %{quiz: quiz, respondent: respondent} do
    test_channel = TestChannel.new(true, false)
    channel = build(:channel, settings: test_channel |> TestChannel.settings)

    fallback_runtime_channel = TestChannel.new
    fallback_channel = build(:channel, settings: fallback_runtime_channel |> TestChannel.settings, type: "ivr")
    fallback_retries = [5]

    {:ok, session = %Session{token: token}, _, 10, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always(), [], fallback_channel, "ivr", fallback_retries)
    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    assert {:ok, ^session, %Reply{}, 10, _} = Session.timeout(session)
  end

  test "doesn't consume a retry if it has an expired message" do
    quiz = insert(:questionnaire, steps: @dummy_steps)
    respondent = insert(:respondent)
    test_channel = TestChannel.new(:expired)
    channel = build(:channel, settings: test_channel |> TestChannel.settings)

    assert {:ok, session = %Session{token: token}, _, 5, _} = Session.start(quiz, respondent, channel, "ivr", Schedule.always(), [5])
    assert_receive [:setup, ^test_channel, ^respondent, ^token]

    assert {:ok, %Session{token: token}, %Reply{}, 5, _} = Session.timeout(session)
    assert_receive [:setup, ^test_channel, ^respondent, ^token]
  end

  test "doesn't fail if it has an expired message" do
    quiz = insert(:questionnaire, steps: @dummy_steps)
    respondent = insert(:respondent)
    test_channel = TestChannel.new(:expired)
    channel = build(:channel, settings: test_channel |> TestChannel.settings, type: "ivr")

    assert {:ok, session = %Session{token: token}, _, 10, _} = Session.start(quiz, respondent, channel, "ivr", Schedule.always())
    assert_receive [:setup, ^test_channel, ^respondent, ^token]

    assert {:ok, %Session{token: token}, %Reply{}, 10, _} = Session.timeout(session)
    assert_receive [:setup, ^test_channel, ^respondent, ^token]
  end

  test "doesn't switch to fallback if it has an expired message", %{quiz: quiz, respondent: respondent} do
    test_channel = TestChannel.new(:expired)
    channel = build(:channel, settings: test_channel |> TestChannel.settings)

    fallback_runtime_channel = TestChannel.new
    fallback_channel = build(:channel, settings: fallback_runtime_channel |> TestChannel.settings, type: "ivr")
    fallback_retries = [5]

    {:ok, session = %Session{token: token}, _, 10, _} = Session.start(quiz, respondent, channel, "ivr", Schedule.always(), [], fallback_channel, "ivr", fallback_retries)
    assert_receive [:setup, ^test_channel, ^respondent, ^token]

    assert {:ok, %Session{token: token}, %Reply{}, 10, _} = Session.timeout(session)
    assert_receive [:setup, ^test_channel, ^respondent, ^token]
  end

  test "uses retry configuration", %{quiz: quiz, respondent: respondent, channel: channel} do
    assert {:ok, _, _, 60, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always(), [60])
  end

  test "step", %{quiz: quiz, respondent: respondent, channel: channel} do
    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always())

    step_result = Session.sync_step(session, Flow.Message.reply("N"))
    assert {:ok, %Session{}, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO", %{"Smokes" => "No"}), 10, _} = step_result

    assert [response] = respondent |> Ecto.assoc(:responses) |> Ask.Repo.all
    assert response.field_name == "Smokes"
    assert response.value == "No"
  end

  test "end", %{quiz: quiz, respondent: respondent, channel: channel} do
    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always())

    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("Y"))
    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("N"))
    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("99"))
    {:end, _, _} = Session.sync_step(session, Flow.Message.reply("11"))

    responses = respondent
    |> Ecto.assoc(:responses)
    |> Ecto.Query.order_by(:id)
    |> Ask.Repo.all

    assert [
      %{field_name: "Smokes", value: "Yes"},
      %{field_name: "Exercises", value: "No"},
      %{field_name: "Perfect Number", value: "99"},
      %{field_name: "Question", value: "11"},
      ] = responses
  end

  test "steps with the same variable overrides previous value", %{respondent: respondent, channel: channel} do
    quiz = insert(:questionnaire, steps: @steps_with_duplicate_store)
    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always())

    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("Y"))
    {:end, _, _} = Session.sync_step(session, Flow.Message.reply("N"))

    responses = respondent
    |> Ecto.assoc(:responses)
    |> Ask.Repo.all

    assert [
      %{field_name: "Smokes", value: "Yes"}
    ] = responses
  end

  test "ends when quota is reached at leaf", %{quiz: quiz, respondent: respondent, channel: channel, test_channel: test_channel} do
    survey = respondent.survey

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
          "quota" => 2,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"}, %{"store" => "Exercises", "value" => "No"}],
          "quota" => 3,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"}, %{"store" => "Exercises", "value" => "Yes"}],
          "quota" => 4,
          "count" => 0
        },
      ]
    }

    survey
    |> Repo.preload([:quota_buckets])
    |> Survey.changeset(%{quotas: quotas})
    |> Repo.update!

    respondent = Respondent |> Repo.get(respondent.id)

    {:ok, session = %Session{token: token}, _, _, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always())
    assert_receive [:setup, ^test_channel, ^respondent, ^token]

    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("N"))
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    assert {:rejected, %{steps: [%{prompts: ["Quota completed"]}]}, _} = Session.sync_step(session, Flow.Message.reply("N"))

    # The session won't update the respondent, the broker will
    respondent = Respondent |> Repo.get(respondent.id)
    assert respondent.state == "pending"
    assert respondent.disposition == "registered"
  end

  test "ends when quota is reached at leaf, with more stores", %{quiz: quiz, respondent: respondent, channel: channel} do
    survey = respondent.survey

    quotas = %{
      "vars" => ["Exercises"],
      "buckets" => [
        %{
          "condition" => [%{"store" => "Exercises","value" => "No"}],
          "quota" => 1,
          "count" => 1
        },
        %{
          "condition" => [%{"store" => "Exercises","value" => "Yes"}],
          "quota" => 2,
          "count" => 0
        },
      ]
    }

    survey
    |> Repo.preload([:quota_buckets])
    |> Survey.changeset(%{quotas: quotas})
    |> Repo.update!

    respondent = Respondent |> Repo.get(respondent.id)

    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always())
    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("N"))
    assert {:rejected, %{steps: [%{prompts: ["Quota completed"]}]}, _} = Session.sync_step(session, Flow.Message.reply("N"))
  end

  test "ends when quota is reached at leaf, numeric", %{quiz: quiz, respondent: respondent, channel: channel} do
    survey = respondent.survey

    quotas = %{
      "vars" => ["Smokes", "Perfect Number"],
      "buckets" => [
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"},
                          %{"store" => "Perfect Number", "value" => [20, 30]}],
          "quota" => 1,
          "count" => 1
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"},
                          %{"store" => "Perfect Number", "value" => [31, 40]}],
          "quota" => 2,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"},
                          %{"store" => "Perfect Number", "value" => [20, 30]}],
          "quota" => 1,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"},
                          %{"store" => "Perfect Number", "value" => [31, 40]}],
          "quota" => 2,
          "count" => 0
        },
      ]
    }

    survey
    |> Repo.preload([:quota_buckets])
    |> Survey.changeset(%{quotas: quotas})
    |> Repo.update!

    respondent = Respondent |> Repo.get(respondent.id)

    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always())
    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("N"))
    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("Y"))
    assert {:rejected, %{steps: [%{prompts: ["Quota completed"]}]}, _} = Session.sync_step(session, Flow.Message.reply("25"))
  end

  test "ends only after completing the quota questions", %{quiz: quiz, respondent: respondent, channel: channel} do
    survey = respondent.survey

    quotas = %{
      "vars" => ["Smokes", "Exercises"],
      "buckets" => [
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"},
                          %{"store" => "Exercises", "value" => "No"}],
          "quota" => 1,
          "count" => 1
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"},
                          %{"store" => "Exercises", "value" => "Yes"}],
          "quota" => 2,
          "count" => 2
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"},
                          %{"store" => "Exercises", "value" => "No"}],
          "quota" => 3,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"},
                          %{"store" => "Exercises", "value" => "Yes"}],
          "quota" => 4,
          "count" => 0
        },
      ]
    }

    survey
    |> Repo.preload([:quota_buckets])
    |> Survey.changeset(%{quotas: quotas})
    |> Repo.update!

    respondent = Respondent |> Repo.get(respondent.id)

    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always())

    step_result = Session.sync_step(session, Flow.Message.reply("N"))
    assert {:ok, session, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO", %{"Smokes" => "No"}), 10, _} = step_result

    respondent = Respondent |> Repo.get(respondent.id)
    assert respondent.quota_bucket_id == nil

    assert {:rejected, %{steps: [%{prompts: ["Quota completed"]}]}, _} = Session.sync_step(session, Flow.Message.reply("Y"))
    respondent = Respondent |> Repo.get(respondent.id)

    qb2 = (from q in QuotaBucket, where: q.quota == 2) |> Repo.one
    assert respondent.quota_bucket_id == qb2.id
  end

  test "ends only after completing the quota numeric questions", %{quiz: quiz, respondent: respondent, channel: channel} do
    survey = respondent.survey

    quotas = %{
      "vars" => ["Smokes", "Perfect Number"],
      "buckets" => [
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"},
                          %{"store" => "Perfect Number", "value" => [18,29]}],
          "quota" => 1,
          "count" => 1
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"},
                          %{"store" => "Perfect Number", "value" => [18,29]}],
          "quota" => 2,
          "count" => 2
        }
      ]
    }

    survey
    |> Repo.preload([:quota_buckets])
    |> Survey.changeset(%{quotas: quotas})
    |> Repo.update!

    respondent = Respondent |> Repo.get(respondent.id)

    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always())

    step_result = Session.sync_step(session, Flow.Message.reply("N"))
    assert {:ok, session, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO", %{"Smokes" => "No"}), 10, _} = step_result

    respondent = Respondent |> Repo.get(respondent.id)
    assert respondent.quota_bucket_id == nil

    step_result = Session.sync_step(session, Flow.Message.reply("Y"))
    assert {:ok, session, ReplyHelper.simple("Which is the second perfect number?", "Which is the second perfect number??", %{"Exercises" => "Yes"}), 10, _} = step_result

    assert {:rejected, %{steps: [%{prompts: ["Quota completed"]}]}, _} = Session.sync_step(session, Flow.Message.reply("20"))
    respondent = Respondent |> Repo.get(respondent.id)

    qb2 = (from q in QuotaBucket, where: q.quota == 2) |> Repo.one
    assert respondent.quota_bucket_id == qb2.id
  end

  test "assigns respondent to its bucket", %{quiz: quiz, respondent: respondent, channel: channel} do
    survey = respondent.survey

    quotas = %{
      "vars" => ["Smokes", "Exercises"],
      "buckets" => [
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "No"}],
          "quota" => 1,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "Yes"}],
          "quota" => 2,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"}, %{"store" => "Exercises", "value" => "No"}],
          "quota" => 3,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"}, %{"store" => "Exercises", "value" => "Yes"}],
          "quota" => 4,
          "count" => 0
        },
      ]
    }

    survey
    |> Repo.preload([:quota_buckets])
    |> Survey.changeset(%{quotas: quotas})
    |> Repo.update!

    qb2 = (from q in QuotaBucket, where: q.quota == 2) |> Repo.one

    respondent = Respondent |> Repo.get(respondent.id)
    assert respondent.quota_bucket_id == nil

    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always())

    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("N"))
    respondent = Respondent |> Repo.get(respondent.id)
    assert respondent.quota_bucket_id == nil

    Session.sync_step(session, Flow.Message.reply("Y"))
    respondent = Respondent |> Repo.get(respondent.id)
    assert respondent.quota_bucket_id == qb2.id
  end

  test "assigns respondent to its bucket, with more responses", %{quiz: quiz, respondent: respondent, channel: channel} do
    survey = respondent.survey

    quotas = %{
      "vars" => ["Exercises"],
      "buckets" => [
        %{
          "condition" => [%{"store" => "Exercises", "value" => "No"}],
          "quota" => 1,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Exercises", "value" => "Yes"}],
          "quota" => 2,
          "count" => 0
        },
      ]
    }

    survey
    |> Repo.preload([:quota_buckets])
    |> Survey.changeset(%{quotas: quotas})
    |> Repo.update!

    qb2 = (from q in QuotaBucket, where: q.quota == 2) |> Repo.one

    respondent = Respondent |> Repo.get(respondent.id)
    assert respondent.quota_bucket_id == nil

    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always())

    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("N"))
    respondent = Respondent |> Repo.get(respondent.id)
    assert respondent.quota_bucket_id == nil

    Session.sync_step(session, Flow.Message.reply("Y"))
    respondent = Respondent |> Repo.get(respondent.id)
    assert respondent.quota_bucket_id == qb2.id
  end

  test "assigns respondent to its bucket, numeric condition", %{quiz: quiz, respondent: respondent, channel: channel} do
    survey = respondent.survey

    quotas = %{
      "vars" => ["Smokes", "Exercises"],
      "buckets" => [
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"},
                          %{"store" => "Perfect Number", "value" => [20, 30]}],
          "quota" => 1,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"},
                          %{"store" => "Perfect Number", "value" => [31, 40]}],
          "quota" => 2,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"},
                          %{"store" => "Perfect Number", "value" => [20, 30]}],
          "quota" => 3,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"},
                          %{"store" => "Perfect Number", "value" => [31, 40]}],
          "quota" => 4,
          "count" => 0
        },
      ]
    }

    survey
    |> Repo.preload([:quota_buckets])
    |> Survey.changeset(%{quotas: quotas})
    |> Repo.update!

    qb2 = (from q in QuotaBucket, where: q.quota == 2) |> Repo.one

    respondent = Respondent |> Repo.get(respondent.id)
    assert respondent.quota_bucket_id == nil

    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always())

    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("N"))
    respondent = Respondent |> Repo.get(respondent.id)
    assert respondent.quota_bucket_id == nil

    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("Y"))
    respondent = Respondent |> Repo.get(respondent.id)
    assert respondent.quota_bucket_id == nil

    {:ok, _session, _, _, _} = Session.sync_step(session, Flow.Message.reply("33"))
    respondent = Respondent |> Repo.get(respondent.id)
    assert respondent.quota_bucket_id == qb2.id
  end

  test "flag with prompt", %{respondent: respondent, channel: channel} do
    quiz = insert(:questionnaire, steps: @flag_steps)
    {:ok, _, %{disposition: disposition}, _, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always())

    assert disposition == "interim partial"
  end

  test "flag and end", %{respondent: respondent, channel: channel} do
    quiz = build(:questionnaire, steps: @partial_step)
    {:end, %{disposition: disposition}, _} = Session.start(quiz, respondent, channel, "sms", Schedule.always())

    assert disposition == "interim partial"
  end
end
