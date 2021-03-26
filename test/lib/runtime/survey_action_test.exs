defmodule Ask.SurveyActionTest do
  use Ask.ModelCase
  alias Ask.Runtime.{SurveyAction, RespondentGroupAction}
  alias Ask.{Survey, Repo, TestChannel, Respondent, ActivityLog}

  describe "repeat" do
    test "repeats a panel survey" do
      survey = completed_panel_survey()

      {result, data} = SurveyAction.repeat(survey)

      assert result == :ok
      new_occurrence = Map.get(data, :survey)
      assert new_occurrence
      assert new_occurrence.state == "running"
      assert new_occurrence.panel_survey_of == survey.panel_survey_of
      assert new_occurrence.latest_panel_survey
      survey = Repo.get!(Survey, survey.id)
      refute survey.latest_panel_survey
    end

    test "preserves the incentives enabled flag" do
      # Incentives enabled
      survey = completed_panel_survey()

      {:ok, %{survey: %{incentives_enabled: incentives_enabled}}} = SurveyAction.repeat(survey)

      assert incentives_enabled

      # Incentives disabled
      survey =
        completed_panel_survey()
        |> Survey.changeset(%{incentives_enabled: false})
        |> Repo.update!()

      {:ok, %{survey: %{incentives_enabled: incentives_enabled}}} = SurveyAction.repeat(survey)

      refute incentives_enabled
    end

    test "removes start_date and end_date of the schedule" do
      survey = completed_panel_survey()
      start_date = ~D[2016-01-01]
      end_date = ~D[2016-02-01]
      schedule = set_start_date(survey.schedule, start_date)
      |> set_end_date(end_date)
      survey = set_schedule(survey, schedule)

      {result, data} = SurveyAction.repeat(survey)
      assert result == :ok
      assert survey.schedule
      assert survey.schedule.start_date == start_date
      assert survey.schedule.end_date == end_date
      new_occurrence = Map.get(data, :survey)
      assert new_occurrence
      assert new_occurrence.schedule
      refute new_occurrence.schedule.start_date
      refute new_occurrence.schedule.end_date
    end

    test "doesn't repeat a regular survey" do
      survey = regular_survey()

      {result, data} = SurveyAction.repeat(survey)

      assert result == :error
      assert Map.get(data, :survey) == survey
    end

    test "doesn't repeat a not terminated panel survey" do
      survey = panel_survey()

      {result, data} = SurveyAction.repeat(survey)

      assert result == :error
      assert Map.get(data, :survey) == survey
    end

    test "only repeats the latest occurrence" do
      survey = repeated_survey()

      {result, data} = SurveyAction.repeat(survey)

      assert result == :error
      assert Map.get(data, :survey) == survey
    end

    test "preserves every respondent with their hashed phone number and mode/channel associations" do
      survey = completed_panel_survey_with_respondents()

      {result, data} = SurveyAction.repeat(survey)

      assert result == :ok
      new_occurrence = Map.get(data, :survey)
      assert new_occurrence
      assert respondent_channels(survey) == respondent_channels(new_occurrence)
    end

    test "doesn't preserves the refused respondents" do
      survey = completed_panel_survey_with_respondents()
      refused_respondent = refuse_one_respondent(survey)

      {result, data} = SurveyAction.repeat(survey)

      assert result == :ok
      new_occurrence = Map.get(data, :survey)
      assert new_occurrence
      refute respondent_channels(survey) == respondent_channels(new_occurrence)
      assert respondent_in_survey?(survey, refused_respondent.hashed_number)
      refute respondent_in_survey?(new_occurrence, refused_respondent.hashed_number)
    end
  end

  describe "delete panel surveys" do
    test "if it's the only one, just drop it" do
      survey = completed_panel_survey()

      {result, _data} = delete(survey)

      assert result == :ok
      assert_deleted_survey(survey.id)
    end

    test "removing one in the middle is fine" do
      [first, second, third] = three_panel_survey_incarnations()

      {result, _data} = delete(second)

      assert result == :ok
      assert_deleted_survey(second.id)
      assert_panel_survey(first.id, panel_survey_of: first.id, latest_panel_survey: false, repeatable?: false)
      assert_panel_survey(third.id, panel_survey_of: first.id, latest_panel_survey: true, repeatable?: true)
    end

    test "removing the original should make the second one to act as the original" do
      [first, second, third] = three_panel_survey_incarnations()

      {result, _data} = delete(first)

      assert result == :ok
      assert_deleted_survey(first.id)
      assert_panel_survey(second.id, panel_survey_of: second.id, latest_panel_survey: false, repeatable?: false)
      assert_panel_survey(third.id, panel_survey_of: second.id, latest_panel_survey: true, repeatable?: true)
    end

    test "removing the last one should allow the user to create a new incarnation from the previous one from the normal flow" do
      [first, second, third] = three_panel_survey_incarnations()

      {result, _data} = delete(third)

      assert result == :ok
      assert_deleted_survey(third.id)
      assert_panel_survey(first.id, panel_survey_of: first.id, latest_panel_survey: false, repeatable?: false)
      assert_panel_survey(second.id, panel_survey_of: first.id, latest_panel_survey: true, repeatable?: true)
    end
  end

  defp delete(survey) do
    SurveyAction.delete(survey, nil)
  end

  defp respondent_channels(survey) do
    survey =
      survey
      |> Repo.preload(respondents: [respondent_group: [respondent_group_channels: :channel]])

    Enum.map(survey.respondents, fn %{
                                      hashed_number: hashed_number,
                                      respondent_group: respondent_group
                                    } ->
      respondent_group_channels =
        Enum.map(respondent_group.respondent_group_channels, fn %{channel: channel, mode: mode} ->
          %{channel_id: channel.id, mode: mode}
        end)

      %{hashed_number: hashed_number, respondent_group_channels: respondent_group_channels}
    end)
  end

  defp regular_survey() do
    project = insert(:project)
    insert(:survey, project: project)
  end

  defp switch_to_panel_survey(survey) do
    Survey.changeset(survey, %{panel_survey_of: survey.id, latest_panel_survey: true})
    |> Repo.update!()
  end

  defp panel_survey() do
    regular_survey() |> switch_to_panel_survey()
  end

  defp complete(survey) do
    survey
    |> Survey.changeset(%{state: "terminated"})
    |> Repo.update!()
  end

  defp completed_panel_survey() do
    panel_survey() |> complete
  end

  defp repeat(survey) do
    {:ok, %{survey: new_occurrence}} = SurveyAction.repeat(survey)
    %{
      repeated_survey: Repo.get(Survey, survey.id),
      new_occurrence: new_occurrence
    }
  end

  defp set_schedule(survey, schedule) do
    Survey.changeset(survey, %{schedule: schedule})
    |> Repo.update!()
  end

  defp set_start_date(schedule, start_date) do
    Map.put(schedule, :start_date, start_date)
  end

  defp set_end_date(schedule, end_date) do
    Map.put(schedule, :end_date, end_date)
  end

  defp repeated_survey() do
    survey = completed_panel_survey()
    %{repeated_survey: repeated_survey} = repeat(survey)
    repeated_survey
  end

  defp completed_panel_survey_with_respondents() do
    survey = panel_survey()

    insert_respondents = fn mode, phone_numbers ->
      channel = TestChannel.new()
      channel = insert(:channel, settings: channel |> TestChannel.settings(), type: mode)
      insert_respondents(survey, channel, mode, phone_numbers)
    end

    insert_respondents.("sms", ["1", "2", "3"])
    insert_respondents.("ivr", ["3", "4"])
    complete(survey)
  end

  defp insert_respondents(survey, channel, mode, phone_numbers) do
    phone_numbers = RespondentGroupAction.loaded_phone_numbers(phone_numbers)
    group = RespondentGroupAction.create(UUID.uuid4(), phone_numbers, survey)
    RespondentGroupAction.update_channels(group.id, [%{"id" => channel.id, "mode" => mode}])
  end

  defp refuse_one_respondent(survey) do
    survey
    |> assoc(:respondents)
    |> limit(1)
    |> Repo.one!()
    |> Respondent.changeset(%{disposition: "refused"})
    |> Repo.update!()
  end

  defp respondent_in_survey?(survey, hashed_number) do
    respondent =
      survey
      |> assoc(:respondents)
      |> Repo.get_by(hashed_number: hashed_number)

    !!respondent
  end

  defp assert_deleted_survey(survey_id) do
    refute Repo.get(Survey, survey_id)
    assert survey_id == Repo.one(ActivityLog).entity_id
  end

  defp assert_panel_survey(survey_id, options) do
    survey = Repo.get(Survey, survey_id)
    assert survey
    assert Survey.panel_survey?(survey)

    panel_survey_of = Keyword.get(options, :panel_survey_of, nil)
    if panel_survey_of do
      assert survey.panel_survey_of == panel_survey_of
    end
    latest_panel_survey = Keyword.get(options, :latest_panel_survey, nil)
    if latest_panel_survey != nil do
      assert survey.latest_panel_survey == latest_panel_survey
    end
    repeatable? = Keyword.get(options, :repeatable, nil)
    if repeatable? != nil do
      assert Survey.repeatable?(survey) == repeatable?
    end
  end

  defp three_panel_survey_incarnations() do
    first = completed_panel_survey()
    %{
      repeated_survey: first,
      new_occurrence: second
    } = repeat(first)
    second = complete(second)
    %{
      repeated_survey: second,
      new_occurrence: third
    } = repeat(second)
    third = complete(third)
    [first, second, third]
  end
end
