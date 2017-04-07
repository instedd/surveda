defmodule Ask.SessionTest do
  use Ask.ModelCase
  use Ask.DummySteps
  import Ask.Factory
  alias Ask.Runtime.Session
  alias Ask.Runtime.SessionModeProvider
  alias Ask.TestChannel
  alias Ask.Runtime.{Flow, Reply, ReplyHelper}
  alias Ask.{Survey, Respondent, QuotaBucket, Questionnaire}
  require Ask.Runtime.ReplyHelper

  setup do
    quiz = insert(:questionnaire, steps: @dummy_steps)
    respondent = insert(:respondent)
    test_channel = TestChannel.new
    channel = build(:channel, settings: test_channel |> TestChannel.settings)
    {:ok, quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel}
  end

  test "start", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    {:ok, session, _, timeout, _} = Session.start(quiz, respondent, channel, "sms")
    assert %Session{token: token} = session
    assert 10 = timeout
    assert token != nil

    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]
  end

  test "start with web mode", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    {:ok, session, _, timeout, _} = Session.start(quiz, respondent, channel, "mobileweb")
    assert %Session{token: token} = session
    assert 10 = timeout
    assert token != nil

    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Contact", message)]
    assert message == "Please enter to http://app.ask.dev/mobile_survey/#{respondent.id}"
  end

  test "reloading the page should not consume retries in mobileweb mode", %{respondent: respondent, test_channel: test_channel, channel: channel} do
    quiz = insert(:questionnaire, steps: @mobileweb_dummy_steps)
    retries = [1, 2, 3]

    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "mobileweb", retries)
    assert %Session{token: token} = session
    assert token != nil

    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Contact", message)]
    assert message == "Please enter to http://app.ask.dev/mobile_survey/#{respondent.id}"

    assert {:ok, %Session{current_mode: %{retries: ^retries}} = session, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO"), _, _} = Session.sync_step(session, Flow.Message.answer())
    assert {:ok, %Session{current_mode: %{retries: ^retries}} = session, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO"), _, _} = Session.sync_step(session, Flow.Message.answer())
    assert {:ok, %Session{current_mode: %{retries: ^retries}} = session, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO"), _, _} = Session.sync_step(session, Flow.Message.answer())

    expected_session = %Session{
      current_mode: SessionModeProvider.new("mobileweb", channel, retries),
      fallback_mode: nil,
      flow: %Flow{questionnaire: quiz, mode: "mobileweb", current_step: 0}
    }

    assert session.current_mode == expected_session.current_mode
    assert session.fallback_mode == expected_session.fallback_mode
    assert session.flow.questionnaire == expected_session.flow.questionnaire
    assert session.flow.mode == expected_session.flow.mode
    assert session.flow.current_step == expected_session.flow.current_step

    step_result = Session.sync_step(session, Flow.Message.reply("No"))
    assert {:ok, session, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO", %{"Smokes" => "No"}), _, _} = step_result

    assert {:ok, %Session{current_mode: %{retries: ^retries}} = session, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO"), _, _} = Session.sync_step(session, Flow.Message.answer())
    assert {:ok, %Session{current_mode: %{retries: ^retries}} = session, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO"), _, _} = Session.sync_step(session, Flow.Message.answer())
    assert {:ok, %Session{current_mode: %{retries: ^retries}} = session, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO"), _, _} = Session.sync_step(session, Flow.Message.answer())

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
  end

  test "start with fallback delay", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    {:ok, session, _, timeout, _} = Session.start(quiz, respondent, channel, "sms", [], nil, nil, nil, 123)
    assert %Session{token: token} = session
    assert 123 = timeout
    assert token != nil

    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]
  end

  test "start with channel without push", %{quiz: quiz, respondent: respondent} do
    test_channel = TestChannel.new
    channel = build(:channel, settings: test_channel |> TestChannel.settings)

    {:ok, session, _, timeout, _} = Session.start(quiz, respondent, channel, "ivr")

    assert %Session{token: token} = session
    assert 10 = timeout
    assert token != nil

    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    refute_receive _

    assert session.channel_state == 0
  end

  test "retry question", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    assert {:ok, session = %Session{token: token}, _, 5, _} = Session.start(quiz, respondent, channel, "sms", [5])
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

    {:ok, session = %Session{token: token}, _, 5, _} = Session.start(quiz, respondent, channel, "ivr", [5])
    assert_receive [:setup, ^test_channel, ^respondent, ^token]

    assert {:ok, %Session{token: token2}, _, 10, _} = Session.timeout(session)
    assert token2 != token
    assert_receive [:setup, ^test_channel, ^respondent, ^token2]
  end

  test "last retry", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    {:ok, session = %Session{token: token}, _, 10, _} = Session.start(quiz, respondent, channel, "sms")
    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    assert {:stalled, _, _} = Session.timeout(session)
  end

  test "doesn't retry if has queued message" do
    quiz = insert(:questionnaire, steps: @dummy_steps)
    respondent = insert(:respondent)
    test_channel = TestChannel.new(true)
    channel = build(:channel, settings: test_channel |> TestChannel.settings)

    assert {:ok, session = %Session{token: token}, _, 5, _} = Session.start(quiz, respondent, channel, "sms", [5])
    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    assert {:ok, ^session, %Reply{}, 5, _} = Session.timeout(session)
  end

  test "mark respondent as failed when failure notification arrives on last retry", %{quiz: quiz, respondent: respondent, channel: channel} do
    {:ok, session = %Session{}, _, 10, _} = Session.start(quiz, respondent, channel, "sms")
    assert :failed = Session.channel_failed(session, 'failed')
  end

  test "ignore failure notification when channel fails but there are retries", %{quiz: quiz, respondent: respondent, channel: channel} do
    {:ok, session = %Session{}, _, 5, _} = Session.start(quiz, respondent, channel, "sms", [5])
    assert :ok = Session.channel_failed(session, 'failed')
  end

  test "ignore failure notification when channel fails but there is a fallback channel", %{quiz: quiz, respondent: respondent, channel: channel} do
    {:ok, session = %Session{}, _, 10, _} = Session.start(quiz, respondent, channel, "sms", [], channel, "sms")
    assert :ok = Session.channel_failed(session, 'failed')
  end

  # Primary SMS fallbacks to IVR
  test "switch to fallback after last retry", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    fallback_runtime_channel = TestChannel.new
    fallback_channel = build(:channel, settings: fallback_runtime_channel |> TestChannel.settings, type: "ivr")
    fallback_retries = [5]

    {:ok, session = %Session{token: token}, _, 10, _} = Session.start(quiz, respondent, channel, "sms", [], fallback_channel, "ivr", fallback_retries)
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

    {:ok, session = %Session{token: token}, _, 2, _} = Session.start(quiz, respondent, channel, "sms", [2], fallback_channel, "ivr", fallback_retries)
    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    expected_session = %Session{
      current_mode: SessionModeProvider.new("ivr", fallback_channel, fallback_retries),
      fallback_mode: nil,
      flow: %Flow{questionnaire: quiz, mode: fallback_channel.type, current_step: session.flow.current_step}
    }

    {:ok, result = %Session{token: token}, _, 7, _} = Session.timeout(session)
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

    {:ok, session = %Session{token: token}, _, 2, _} = Session.start(quiz, respondent, channel, "sms", [2, 3], fallback_channel, "ivr", fallback_retries)
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

    {:ok, result = %Session{token: token}, _, 5, _} = Session.timeout(session)
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

    {:ok, session = %Session{token: token}, _, 10, _} = Session.start(quiz, respondent, channel, "sms", [], fallback_channel, "ivr", fallback_retries)
    assert_receive [:setup, ^test_channel, ^respondent, ^token]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    assert {:ok, ^session, %Reply{}, 10, _} = Session.timeout(session)
  end

  test "uses retry configuration", %{quiz: quiz, respondent: respondent, channel: channel} do
    assert {:ok, _, _, 60, _} = Session.start(quiz, respondent, channel, "sms", [60])
  end

  test "step", %{quiz: quiz, respondent: respondent, channel: channel} do
    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms")

    step_result = Session.sync_step(session, Flow.Message.reply("N"))
    assert {:ok, %Session{}, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO", %{"Smokes" => "No"}), 10, _} = step_result

    assert [response] = respondent |> Ecto.assoc(:responses) |> Ask.Repo.all
    assert response.field_name == "Smokes"
    assert response.value == "No"
  end

  test "end", %{quiz: quiz, respondent: respondent, channel: channel} do
    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms")

    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("Y"))
    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("N"))
    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("99"))
    {:end, _} = Session.sync_step(session, Flow.Message.reply("11"))

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
    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms")

    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("Y"))
    {:end, _} = Session.sync_step(session, Flow.Message.reply("N"))

    responses = respondent
    |> Ecto.assoc(:responses)
    |> Ask.Repo.all

    assert [
      %{field_name: "Smokes", value: "Yes"}
    ] = responses
  end

  test "ends when quota is reached at leaf", %{quiz: quiz, respondent: respondent, channel: channel, test_channel: test_channel} do
    quiz = quiz |> Questionnaire.changeset(%{quota_completed_msg: %{"en" => %{"sms" => "Bye!"}}}) |> Repo.update!

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

    {:ok, session = %Session{token: token}, _, _, _} = Session.start(quiz, respondent, channel, "sms")
    assert_receive [:setup, ^test_channel, ^respondent, ^token]

    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("N"))
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    {:rejected, ReplyHelper.quota_completed("Bye!"), _} = Session.sync_step(session, Flow.Message.reply("N"))
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

    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms")
    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("N"))
    {:rejected, ReplyHelper.quota_completed("Quota completed"), _} = Session.sync_step(session, Flow.Message.reply("N"))
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

    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms")
    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("N"))
    {:ok, session, _, _, _} = Session.sync_step(session, Flow.Message.reply("Y"))
    {:rejected, ReplyHelper.quota_completed("Quota completed"), _} = Session.sync_step(session, Flow.Message.reply("25"))
  end

  test "ends when quota is reached at node", %{quiz: quiz, respondent: respondent, channel: channel} do
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

    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms")
    assert {:rejected, ReplyHelper.quota_completed("Quota completed"), _} = Session.sync_step(session, Flow.Message.reply("N"))
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

    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms")

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

    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms")

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

    {:ok, session, _, _, _} = Session.start(quiz, respondent, channel, "sms")

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
    {:ok, _, %{disposition: disposition}, _, _} = Session.start(quiz, respondent, channel, "sms")

    assert disposition == "partial"
  end

  test "flag and end", %{respondent: respondent, channel: channel} do
    quiz = build(:questionnaire, steps: @partial_step)
    {:end, %{disposition: disposition}, _} = Session.start(quiz, respondent, channel, "sms")

    assert disposition == "partial"
  end
end
