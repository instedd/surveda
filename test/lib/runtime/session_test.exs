defmodule Ask.SessionTest do
  use ExUnit.Case
  use Ask.DummySteps
  import Ask.Factory
  alias Ask.Runtime.{Channel, Session}

  defmodule TestChannel do
    defstruct [:pid]
  end

  defimpl Channel, for: TestChannel do
    def ask(channel, phone_number, prompts) do
      send channel.pid, [:ask, channel, phone_number, prompts]
    end
  end

  test "start" do
    quiz = build(:questionnaire, steps: @dummy_steps)
    phone_number = "1234"
    channel = %TestChannel{pid: self()}

    session = Session.start(quiz, phone_number, channel)

    assert_receive [:ask, ^channel, ^phone_number, ["Do you smoke?"]]
    assert %Session{} = session
  end

  test "step" do
    quiz = build(:questionnaire, steps: @dummy_steps)
    phone_number = "1234"
    channel = %TestChannel{pid: self()}
    session = Session.start(quiz, phone_number, channel)

    step_result = Session.sync_step(session)
    assert {:ok, %Session{}, {:prompt, "Do you exercise?"}} = step_result
  end

  test "end" do
    quiz = build(:questionnaire, steps: @dummy_steps)
    phone_number = "1234"
    channel = %TestChannel{pid: self()}
    session = Session.start(quiz, phone_number, channel)

    {:ok, session, _} = Session.sync_step(session)
    step_result = Session.sync_step(session)
    assert :end == step_result
  end
end
