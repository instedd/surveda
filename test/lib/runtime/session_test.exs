defmodule Ask.SessionTest do
  use ExUnit.Case
  use Ask.DummySteps
  import Ask.Factory
  alias Ask.Runtime.Session
  alias Ask.TestChannel

  test "start" do
    quiz = build(:questionnaire, steps: @dummy_steps)
    phone_number = "1234"
    test_channel = TestChannel.new
    channel = build(:channel, settings: test_channel |> TestChannel.settings)

    session = Session.start(quiz, phone_number, channel)

    assert_receive [:ask, ^test_channel, ^phone_number, ["Do you smoke?"]]
    assert %Session{} = session
  end

  test "step" do
    quiz = build(:questionnaire, steps: @dummy_steps)
    phone_number = "1234"
    test_channel = TestChannel.new
    channel = build(:channel, settings: test_channel |> TestChannel.settings)
    session = Session.start(quiz, phone_number, channel)

    step_result = Session.sync_step(session, "No")
    assert {:ok, %Session{}, {:prompt, "Do you exercise?"}} = step_result
  end

  test "end" do
    quiz = build(:questionnaire, steps: @dummy_steps)
    phone_number = "1234"
    test_channel = TestChannel.new
    channel = build(:channel, settings: test_channel |> TestChannel.settings)
    session = Session.start(quiz, phone_number, channel)

    {:ok, session, _} = Session.sync_step(session, "Yes")
    step_result = Session.sync_step(session, "No")
    assert :end == step_result
  end
end
