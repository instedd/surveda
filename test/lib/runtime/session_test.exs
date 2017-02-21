defmodule Ask.SessionTest do
  use Ask.ModelCase
  use Ask.DummySteps
  import Ask.Factory
  alias Ask.Runtime.Session
  alias Ask.TestChannel
  alias Ask.Runtime.{Flow, Reply}
  alias Ask.{Survey, Respondent, QuotaBucket, Questionnaire}

  setup do
    quiz = insert(:questionnaire, steps: @dummy_steps)
    respondent = insert(:respondent)
    test_channel = TestChannel.new
    channel = build(:channel, settings: test_channel |> TestChannel.settings)
    {:ok, quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel}
  end

  test "start", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    {:ok, session, _, timeout} = Session.start(quiz, respondent, channel)
    assert %Session{token: token} = session
    assert 10 = timeout
    assert token != nil

    assert_receive [:setup, ^test_channel, ^respondent, ^token, nil]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ["Do you smoke? Reply 1 for YES, 2 for NO"]]
  end

  test "start with fallback delay", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    {:ok, session, _, timeout} = Session.start(quiz, respondent, channel, [], nil, nil, 123)
    assert %Session{token: token} = session
    assert 123 = timeout
    assert token != nil

    assert_receive [:setup, ^test_channel, ^respondent, ^token, nil]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ["Do you smoke? Reply 1 for YES, 2 for NO"]]
  end

  test "start with channel without push", %{quiz: quiz, respondent: respondent} do
    test_channel = TestChannel.new(false)
    channel = build(:channel, settings: test_channel |> TestChannel.settings)

    {:ok, session, _, timeout} = Session.start(quiz, respondent, channel)

    assert %Session{token: token} = session
    assert 10 = timeout
    assert token != nil

    assert_receive [:setup, ^test_channel, ^respondent, ^token, nil]
    refute_receive _

    assert session.channel_state == 0
  end

  test "retry question", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    assert {:ok, session = %Session{token: token}, _, 5} = Session.start(quiz, respondent, channel, [5])
    assert_receive [:setup, ^test_channel, ^respondent, ^token, nil]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ["Do you smoke? Reply 1 for YES, 2 for NO"]]

    assert {:ok, session = %Session{token: token2}, _, 10} = Session.timeout(session)
    assert token2 != token
    assert_receive [:ask, ^test_channel, ^respondent, ^token2, ["Do you smoke? Reply 1 for YES, 2 for NO"]]

    assert {:stalled, _} = Session.timeout(session)
  end

  test "retry with IVR channel", %{quiz: quiz, respondent: respondent} do
    test_channel = TestChannel.new(false)
    channel = build(:channel, settings: test_channel |> TestChannel.settings)

    {:ok, session = %Session{token: token}, _, 5} = Session.start(quiz, respondent, channel, [5])
    assert_receive [:setup, ^test_channel, ^respondent, ^token, nil]

    assert {:ok, %Session{token: token2}, _, 10} = Session.timeout(session)
    assert token2 != token
    assert_receive [:setup, ^test_channel, ^respondent, ^token2, 0]
  end

  test "last retry", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    {:ok, session = %Session{token: token}, _, 10} = Session.start(quiz, respondent, channel)
    assert_receive [:setup, ^test_channel, ^respondent, ^token, nil]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ["Do you smoke? Reply 1 for YES, 2 for NO"]]

    assert {:stalled, _} = Session.timeout(session)
  end

  test "mark respondent as failed when failure notification arrives on last retry", %{quiz: quiz, respondent: respondent, channel: channel} do
    {:ok, session = %Session{token: token}, _, 10} = Session.start(quiz, respondent, channel)
    assert :failed = Session.channel_failed(session, token)
  end

  test "ignore failure notification if token doesn't match", %{quiz: quiz, respondent: respondent, channel: channel} do
    {:ok, session, _, 10} = Session.start(quiz, respondent, channel)
    assert :ok = Session.channel_failed(session, "1234")
  end

  test "ignore failure notification when channel fails but there are retries", %{quiz: quiz, respondent: respondent, channel: channel} do
    {:ok, session = %Session{token: token}, _, 5} = Session.start(quiz, respondent, channel, [5])
    assert :ok = Session.channel_failed(session, token)
  end

  test "ignore failure notification when channel fails but there is a fallback channel", %{quiz: quiz, respondent: respondent, channel: channel} do
    {:ok, session = %Session{token: token}, _, 10} = Session.start(quiz, respondent, channel, [], channel)
    assert :ok = Session.channel_failed(session, token)
  end

  # Primary SMS fallbacks to IVR
  test "switch to fallback after last retry", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    fallback_runtime_channel = TestChannel.new(false)
    fallback_channel = build(:channel, settings: fallback_runtime_channel |> TestChannel.settings, type: "ivr")
    fallback_retries = [5]

    {:ok, session = %Session{token: token}, _, 10} = Session.start(quiz, respondent, channel, [], fallback_channel, fallback_retries)
    assert_receive [:setup, ^test_channel, ^respondent, ^token, nil]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ["Do you smoke? Reply 1 for YES, 2 for NO"]]

    expected_session = %Session{
      channel: fallback_channel,
      retries: fallback_retries,
      fallback: nil,
      flow: %Flow{questionnaire: quiz, mode: fallback_channel.type, current_step: session.flow.current_step}
    }

    {:ok, result = %Session{token: token}, _, 5} = Session.timeout(session)
    assert_receive [:setup, ^fallback_runtime_channel, ^respondent, ^token, 0]

    assert result.channel == expected_session.channel
    assert result.retries == expected_session.retries
    assert result.fallback == expected_session.fallback
    assert result.flow.questionnaire == expected_session.flow.questionnaire
    assert result.flow.mode == expected_session.flow.mode
    assert result.flow.current_step == expected_session.flow.current_step
  end

  # Primary SMS retries SMS and then fallbacks to IVR
  test "switch to fallback after specified time", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    fallback_runtime_channel = TestChannel.new(false)
    fallback_channel = build(:channel, settings: fallback_runtime_channel |> TestChannel.settings, type: "ivr")
    fallback_retries = [7]

    {:ok, session = %Session{token: token}, _, 2} = Session.start(quiz, respondent, channel, [2], fallback_channel, fallback_retries)
    assert_receive [:setup, ^test_channel, ^respondent, ^token, nil]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ["Do you smoke? Reply 1 for YES, 2 for NO"]]

    expected_session = %Session{
      channel: fallback_channel,
      retries: fallback_retries,
      fallback: nil,
      flow: %Flow{questionnaire: quiz, mode: fallback_channel.type, current_step: session.flow.current_step}
    }

    {:ok, result = %Session{token: token}, _, 7} = Session.timeout(session)
    assert_receive [:setup, ^fallback_runtime_channel, ^respondent, ^token, 0]

    assert result.channel == expected_session.channel
    assert result.retries == expected_session.retries
    assert result.fallback == expected_session.fallback
    assert result.flow.questionnaire == expected_session.flow.questionnaire
    assert result.flow.mode == expected_session.flow.mode
    assert result.flow.current_step == expected_session.flow.current_step
  end

  # Primary SMS retries SMS and then fallbacks to IVR
  test "switch to fallback after retrying twice", %{quiz: quiz, respondent: respondent, test_channel: test_channel, channel: channel} do
    fallback_runtime_channel = TestChannel.new(false)
    fallback_channel = build(:channel, settings: fallback_runtime_channel |> TestChannel.settings, type: "ivr")
    fallback_retries = [5]

    {:ok, session = %Session{token: token}, _, 2} = Session.start(quiz, respondent, channel, [2, 3], fallback_channel, fallback_retries)
    assert_receive [:setup, ^test_channel, ^respondent, ^token, nil]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ["Do you smoke? Reply 1 for YES, 2 for NO"]]

    expected_session = %Session{
      channel: fallback_channel,
      retries: fallback_retries,
      fallback: nil,
      flow: %Flow{questionnaire: quiz, mode: fallback_channel.type, current_step: session.flow.current_step}
    }

    {:ok, session = %Session{token: token}, _, 3} = Session.timeout(session)
    refute_receive [:setup, _, _, _, _]
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ["Do you smoke? Reply 1 for YES, 2 for NO"]]

    {:ok, result = %Session{token: token}, _, 5} = Session.timeout(session)
    assert_receive [:setup, ^fallback_runtime_channel, ^respondent, ^token, 0]

    assert result.channel == expected_session.channel
    assert result.retries == expected_session.retries
    assert result.fallback == expected_session.fallback
    assert result.flow.questionnaire == expected_session.flow.questionnaire
    assert result.flow.mode == expected_session.flow.mode
    assert result.flow.current_step == expected_session.flow.current_step
  end

  test "uses retry configuration", %{quiz: quiz, respondent: respondent, channel: channel} do
    assert {:ok, _, _, 60} = Session.start(quiz, respondent, channel, [60])
  end

  test "step", %{quiz: quiz, respondent: respondent, channel: channel} do
    {:ok, session, _, _} = Session.start(quiz, respondent, channel)

    step_result = Session.sync_step(session, Flow.Message.reply("N"))
    assert {:ok, %Session{}, %Reply{prompts: ["Do you exercise? Reply 1 for YES, 2 for NO"]}, 10} = step_result

    assert [response] = respondent |> Ecto.assoc(:responses) |> Ask.Repo.all
    assert response.field_name == "Smokes"
    assert response.value == "No"
  end

  test "end", %{quiz: quiz, respondent: respondent, channel: channel} do
    {:ok, session, _, _} = Session.start(quiz, respondent, channel)

    {:ok, session, _, _} = Session.sync_step(session, Flow.Message.reply("Y"))
    {:ok, session, _, _} = Session.sync_step(session, Flow.Message.reply("N"))
    {:ok, session, _, _} = Session.sync_step(session, Flow.Message.reply("99"))
    :end = Session.sync_step(session, Flow.Message.reply("11"))

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
    {:ok, session, _, _} = Session.start(quiz, respondent, channel)

    {:ok, session, _, _} = Session.sync_step(session, Flow.Message.reply("Y"))
    :end = Session.sync_step(session, Flow.Message.reply("N"))

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

    {:ok, session = %Session{token: token}, _, _} = Session.start(quiz, respondent, channel)
    assert_receive [:setup, ^test_channel, ^respondent, ^token, nil]

    {:ok, session, _, _} = Session.sync_step(session, Flow.Message.reply("N"))
    assert_receive [:ask, ^test_channel, ^respondent, ^token, ["Do you smoke? Reply 1 for YES, 2 for NO"]]

    {:rejected, %Reply{prompts: ["Bye!"]}} = Session.sync_step(session, Flow.Message.reply("N"))
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

    {:ok, session, _, _} = Session.start(quiz, respondent, channel)
    {:ok, session, _, _} = Session.sync_step(session, Flow.Message.reply("N"))
    {:rejected, %Reply{prompts: ["Quota completed"]}} = Session.sync_step(session, Flow.Message.reply("N"))
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

    {:ok, session, _, _} = Session.start(quiz, respondent, channel)
    {:ok, session, _, _} = Session.sync_step(session, Flow.Message.reply("N"))
    {:ok, session, _, _} = Session.sync_step(session, Flow.Message.reply("Y"))
    {:rejected, %Reply{prompts: ["Quota completed"]}} = Session.sync_step(session, Flow.Message.reply("25"))
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

    {:ok, session, _, _} = Session.start(quiz, respondent, channel)
    {:rejected, %Reply{prompts: ["Quota completed"]}} = Session.sync_step(session, Flow.Message.reply("N"))
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

    {:ok, session, _, _} = Session.start(quiz, respondent, channel)

    {:ok, session, _, _} = Session.sync_step(session, Flow.Message.reply("N"))
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

    {:ok, session, _, _} = Session.start(quiz, respondent, channel)

    {:ok, session, _, _} = Session.sync_step(session, Flow.Message.reply("N"))
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

    {:ok, session, _, _} = Session.start(quiz, respondent, channel)

    {:ok, session, _, _} = Session.sync_step(session, Flow.Message.reply("N"))
    respondent = Respondent |> Repo.get(respondent.id)
    assert respondent.quota_bucket_id == nil

    {:ok, session, _, _} = Session.sync_step(session, Flow.Message.reply("Y"))
    respondent = Respondent |> Repo.get(respondent.id)
    assert respondent.quota_bucket_id == nil

    {:ok, _session, _, _} = Session.sync_step(session, Flow.Message.reply("33"))
    respondent = Respondent |> Repo.get(respondent.id)
    assert respondent.quota_bucket_id == qb2.id
  end

  test "flag with prompt", %{respondent: respondent, channel: channel} do
    quiz = insert(:questionnaire, steps: @flag_steps)
    {:ok, _, %{disposition: disposition}, _} = Session.start(quiz, respondent, channel)

    assert disposition == "partial"
  end

  test "flag and end", %{respondent: respondent, channel: channel} do
    quiz = build(:questionnaire, steps: @partial_step)
    {:end, %{disposition: disposition}} = Session.start(quiz, respondent, channel)

    assert disposition == "partial"
  end
end
