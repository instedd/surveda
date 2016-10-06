defmodule Ask.SessionTest do
  use Ask.ModelCase
  use Ask.DummySteps
  import Ask.Factory
  alias Ask.Runtime.Session
  alias Ask.TestChannel

  test "start" do
    quiz = build(:questionnaire, steps: @dummy_steps)
    respondent = build(:respondent)
    phone_number = respondent.phone_number
    test_channel = TestChannel.new
    channel = build(:channel, settings: test_channel |> TestChannel.settings)

    session = Session.start(quiz, respondent, channel)

    assert_receive [:ask, ^test_channel, ^phone_number, ["Do you smoke?"]]
    assert %Session{} = session
  end

  test "step" do
    quiz = build(:questionnaire, steps: @dummy_steps)
    respondent = insert(:respondent)
    test_channel = TestChannel.new
    channel = build(:channel, settings: test_channel |> TestChannel.settings)
    session = Session.start(quiz, respondent, channel)

    step_result = Session.sync_step(session, "N")
    assert {:ok, %Session{}, {:prompt, "Do you exercise?"}} = step_result

    assert [response] = respondent |> Ecto.assoc(:responses) |> Ask.Repo.all
    assert response.field_name == "Smokes"
    assert response.value == "No"
  end

  test "end" do
    quiz = build(:questionnaire, steps: @dummy_steps)
    respondent = insert(:respondent)
    test_channel = TestChannel.new
    channel = build(:channel, settings: test_channel |> TestChannel.settings)
    session = Session.start(quiz, respondent, channel)

    {:ok, session, _} = Session.sync_step(session, "Y")
    {:ok, session, _} = Session.sync_step(session, "N")
    step_result = Session.sync_step(session, "99")
    assert :end == step_result

    responses = respondent
    |> Ecto.assoc(:responses)
    |> Ecto.Query.order_by(:id)
    |> Ask.Repo.all

    assert [
      %{field_name: "Smokes", value: "Yes"},
      %{field_name: "Exercises", value: "No"},
      %{field_name: "Perfect Number", value: "99"}] = responses
  end
end
