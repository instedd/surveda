defmodule Ask.BrokerTest do
  use Ask.ModelCase
  alias Ask.Runtime.Broker
  alias Ask.{ Repo, Survey, Respondent }

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
    survey = insert(:survey, state: "running")
    respondent = insert(:respondent, survey: survey)

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
  end
end
