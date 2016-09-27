defmodule Ask.BrokerTest do
  use Ask.ModelCase
  use Ask.DummySteps
  alias Ask.Runtime.Broker
  alias Ask.{Repo, Survey, Respondent, TestChannel}

  test "does nothing with 'not_ready' survey" do
    survey = insert(:survey)
    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "not_ready"
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

  test "changes the respondent state from pending to running if neccessary" do
    [survey, _, respondent, _] = create_running_survey_with_channel_and_respondent()

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"
    updated_respondent = Repo.get(Respondent, respondent.id)
    assert updated_respondent.state == "active"
  end

  test "marks the survey as completed when the cutoff is reached" do
    [survey, _, _, _] = create_running_survey_with_channel_and_respondent()
    create_several_respondents(survey, 20)

    Repo.update(survey |> change |> Survey.changeset(%{cutoff: 12}))

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)

    assert survey.state == "running"

    [active, pending] = get_respondents_by_state(survey)

    assert active == 10
    assert pending == 11

    Repo.all(from r in Respondent, where: r.state == "active", limit: 5)
    |> Enum.map(fn respondent ->
      Repo.update(respondent |> change |> Respondent.changeset(%{state: "completed"}))
    end)

    Broker.handle_info(:poll, nil)

    [active, pending] = get_respondents_by_state(survey)

    assert active == 7
    assert pending == 9

    Repo.all(from r in Respondent, where: r.state == "active")
    |> Enum.map(fn respondent ->
      Repo.update(respondent |> change |> Respondent.changeset(%{state: "completed"}))
    end)

    Broker.handle_info(:poll, nil)

    [active, pending] = get_respondents_by_state(survey)

    assert active == 0
    assert pending == 9

    survey = Repo.get(Survey, survey.id)

    assert survey.state == "completed"
  end

  test "always keeps batch_size number of respondents running" do
    [survey, _, _, _] = create_running_survey_with_channel_and_respondent()
    create_several_respondents(survey, 20)

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)

    assert survey.state == "running"

    [active, pending] = get_respondents_by_state(survey)

    assert active == 10
    assert pending == 11

    active_respondent = Repo.all(from r in Respondent, where: r.state == "active")
    |> Enum.at(0)

    Repo.update(active_respondent |> change |> Respondent.changeset(%{state: "failed"}))

    [active, pending] = get_respondents_by_state(survey)

    assert active == 9
    assert pending == 11

    Broker.handle_info(:poll, nil)

    [active, pending] = get_respondents_by_state(survey)

    assert active == 10
    assert pending == 10
  end

  test "changes running survey state to 'completed' when there are no more running respondents" do
    [survey, _, _respondent, _] = create_running_survey_with_channel_and_respondent()

    Broker.handle_info(:poll, nil)

    [active, pending] = get_respondents_by_state(survey)

    assert active == 1
    assert pending == 0

    Repo.update(respondent |> change |> Respondent.changeset(%{state: "failed"}))

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)

    assert survey.state == "completed"
  end

  test "respondent flow" do
    [survey, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent()

    {:ok, broker} = Broker.start_link
    broker |> send(:poll)

    assert_receive [:ask, ^test_channel, ^phone_number, ["Do you smoke?"]]

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"

    reply = Broker.sync_step(respondent, "Yes")
    assert reply == {:prompt, "Do you exercise?"}

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, "Yes")
    assert reply == :end

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "completed"
    assert respondent.session == nil
  end

  def create_running_survey_with_channel_and_respondent() do
    test_channel = TestChannel.new
    channel = insert(:channel, settings: test_channel |> TestChannel.settings)
    quiz = insert(:questionnaire, steps: @dummy_steps)
    survey = insert(:survey, state: "running", questionnaire: quiz) |> Repo.preload([:channels])
    channel_changeset = Ecto.Changeset.change(channel)
    survey |> Ecto.Changeset.change |> Ecto.Changeset.put_assoc(:channels, [channel_changeset]) |> Repo.update
    respondent = insert(:respondent, survey: survey)
    phone_number = respondent.phone_number

    [survey, test_channel, respondent, phone_number]
  end

  def create_several_respondents(survey, n) when n <= 1 do
    [insert(:respondent, survey: survey)]
  end

  def create_several_respondents(survey, n) do
    [create_several_respondents(survey, n - 1) | insert(:respondent, survey: survey)]
  end

  def get_respondents_by_state(survey) do
    by_state = Repo.all(
      from r in assoc(survey, :respondents),
      group_by: :state,
      select: {r.state, count("*")}) |> Enum.into(%{})
    [by_state["active"] || 0, by_state["pending"] || 0]
  end
end
