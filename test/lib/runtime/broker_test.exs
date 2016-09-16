defmodule Ask.BrokerTest do
  use Ask.ModelCase
  use Ask.DummySteps
  alias Ask.Runtime.Broker
  alias Ask.{Repo, Survey, Respondent, TestChannel}

  test "does nothing with 'pending' survey" do
    survey = insert(:survey)
    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "pending"
  end

  test "set as 'completed' when there is no respondents" do
    survey = insert(:survey, state: "running")
    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "completed"
  end

  test "does nothing when there are no pending respondents" do
    survey = insert(:survey, state: "running")
    insert(:respondent, survey: survey, state: "active")

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"
  end

  test "enqueue respondents" do
    test_channel = TestChannel.new
    channel = insert(:channel, settings: test_channel |> TestChannel.settings)
    quiz = insert(:questionnaire, steps: @dummy_steps)
    survey = insert(:survey, state: "running", questionnaire: quiz) |> Repo.preload([:channels])
    channel_changeset = Ecto.Changeset.change(channel)
    survey |> Ecto.Changeset.change |> Ecto.Changeset.put_assoc(:channels, [channel_changeset]) |> Repo.update
    respondent = insert(:respondent, survey: survey)
    phone_number = respondent.phone_number

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"

    assert_receive [:ask, ^test_channel, ^phone_number, ["Do you smoke?"]]
  end
end
