defmodule Ask.SessionTest do
  use ExUnit.Case
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
    quiz = build(:questionnaire, steps: [%{prompt: %{text: "hi"}}])
    phone_number = "1234"
    channel = %TestChannel{pid: self()}

    Session.start(quiz, phone_number, channel)

    assert_receive [:ask, ^channel, ^phone_number, [%{text: "hi"}]]
  end
end
