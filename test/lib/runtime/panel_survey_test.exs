defmodule Ask.Runtime.PanelSurveyTest do
  use Ask.ModelCase
  use Ask.TestHelpers
  alias Ask.Runtime.{PanelSurvey, RespondentGroupAction}
  alias Ask.{Survey, Repo, TestChannel, Respondent}

  describe "new occurence" do
    test "creates a new ready occurrence" do
      panel_survey = completed_panel_survey()

      {result, data} = PanelSurvey.create_panel_survey_occurrence(panel_survey)

      assert result == :ok
      new_occurrence = Map.get(data, :new_occurrence)
      assert new_occurrence
      assert new_occurrence.state == "ready"
      assert new_occurrence.panel_survey_id == panel_survey.id
    end

    test "preserves the incentives enabled flag" do
      panel_survey = incentives_enabled_panel_survey()

      {:ok, %{new_occurrence: new_occurrence}} = PanelSurvey.create_panel_survey_occurrence(panel_survey)

      assert_incentives_enabled(new_occurrence)

      panel_survey = incentives_disabled_panel_survey()

      {:ok, %{new_occurrence: new_occurrence}} = PanelSurvey.create_panel_survey_occurrence(panel_survey)

      assert_incentives_disabled(new_occurrence)
    end

    test "removes start_date and end_date of the schedule" do
      panel_survey = scheduled_panel_survey()
      schedule = Ask.PanelSurvey.latest_occurrence(panel_survey).schedule

      {:ok, %{new_occurrence: new_occurrence}} = PanelSurvey.create_panel_survey_occurrence(panel_survey)

      assert new_occurrence.schedule ==
        clean_dates(schedule)
    end

    test "errors when the latest ocurrence isn't terminated" do
      panel_survey = panel_survey_with_occurrence()

      {result, data} = PanelSurvey.create_panel_survey_occurrence(panel_survey)

      assert result == :error
      assert Map.get(data, :error) == "Last panel survey occurrence isn't terminated"
    end

    test "the new occurence is based on the latest occurrence" do
      panel_survey = completed_panel_survey()
      previous_occurrence = Ask.PanelSurvey.latest_occurrence(panel_survey)
      latest_occurrence = insert(:survey, panel_survey: panel_survey, state: "terminated")

      {:ok, %{new_occurrence: new_occurrence}} = PanelSurvey.create_panel_survey_occurrence(panel_survey)

      # TODO: Don't compare the name, compare something more meaningfull
      refute new_occurrence.name == previous_occurrence.name
      assert latest_occurrence.name == new_occurrence.name
    end

    test "preserves every respondent with their hashed phone number and mode/channel associations" do
      panel_survey = completed_panel_survey_with_respondents()
      latest_occurrence = Ask.PanelSurvey.latest_occurrence(panel_survey)

      {:ok, %{new_occurrence: new_occurrence}} = PanelSurvey.create_panel_survey_occurrence(panel_survey)

      assert respondent_channels(latest_occurrence) == respondent_channels(new_occurrence)
    end

    test "doesn't promote the refused respondents" do
      panel_survey = completed_panel_survey_with_respondents()
      latest_occurrence = Ask.PanelSurvey.latest_occurrence(panel_survey)
      refused_respondent = set_one_respondent_disposition(latest_occurrence, "refused")

      {:ok, %{new_occurrence: new_occurrence}} = PanelSurvey.create_panel_survey_occurrence(panel_survey)

      assert_repeated_without_respondent(latest_occurrence, new_occurrence, refused_respondent)
    end

    test "doesn't promote the ineligible respondents" do
      panel_survey = completed_panel_survey_with_respondents()
      latest_occurrence = Ask.PanelSurvey.latest_occurrence(panel_survey)
      ineligible_respondent = set_one_respondent_disposition(latest_occurrence, "ineligible")

      {:ok, %{new_occurrence: new_occurrence}} = PanelSurvey.create_panel_survey_occurrence(panel_survey)

      assert_repeated_without_respondent(latest_occurrence, new_occurrence, ineligible_respondent)
    end
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

  defp assert_incentives_enabled(survey) do
    assert survey.incentives_enabled
  end

  defp assert_incentives_disabled(survey) do
    refute survey.incentives_enabled
  end

  defp disable_incentives(survey) do
    Survey.changeset(survey, %{incentives_enabled: false})
    |> Repo.update!()
  end

  defp panel_survey_with_occurrence() do
    panel_survey = insert(:panel_survey)
    insert(:survey, panel_survey:  panel_survey)
    # Reload the panel survey. One of its surveys has changed, so it's outdated
    Repo.get!(Ask.PanelSurvey, panel_survey.id)
  end

  defp terminate(survey) do
    Survey.changeset(survey, %{state: "terminated"})
    |> Repo.update!()
  end

  defp completed_panel_survey() do
    panel_survey = panel_survey_with_occurrence()

    Ask.PanelSurvey.latest_occurrence(panel_survey)
    |> terminate()

    # Reload the panel survey. One of its surveys has changed, so it's outdated
    Repo.get!(Ask.PanelSurvey, panel_survey.id)
  end

  defp incentives_enabled_panel_survey() do
    completed_panel_survey()
  end

  defp incentives_disabled_panel_survey() do
    panel_survey =
      completed_panel_survey()

    Ask.PanelSurvey.latest_occurrence(panel_survey)
    |> disable_incentives()

    # Reload the panel survey. One of its surveys has changed, so it's outdated
    Repo.get!(Ask.PanelSurvey, panel_survey.id)
  end

  defp scheduled_panel_survey() do
    panel_survey = completed_panel_survey()
    latest_occurrence = Ask.PanelSurvey.latest_occurrence(panel_survey)
    start_date = ~D[2016-01-01]
    end_date = ~D[2016-02-01]
    schedule = set_start_date(latest_occurrence.schedule, start_date)
    |> set_end_date(end_date)
    set_schedule(latest_occurrence, schedule)

    # Reload the panel survey. One of its surveys has changed, so it's outdated
    Repo.get!(Ask.PanelSurvey, panel_survey.id)
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

  defp clean_dates(schedule) do
    schedule |> Map.put(:start_date, nil) |> Map.put(:end_date, nil)
  end

  defp completed_panel_survey_with_respondents() do
    panel_survey = panel_survey_with_occurrence()
    latest_occurrence = Ask.PanelSurvey.latest_occurrence(panel_survey)

    insert_respondents = fn mode, phone_numbers ->
      channel = TestChannel.new()
      channel = insert(:channel, settings: channel |> TestChannel.settings(), type: mode)
      insert_respondents(latest_occurrence, channel, mode, phone_numbers)
    end

    insert_respondents.("sms", ["1", "2", "3"])
    insert_respondents.("ivr", ["3", "4"])
    terminate(latest_occurrence)

    # Reload the panel survey. One of its surveys has changed, so it's outdated
    Repo.get!(Ask.PanelSurvey, panel_survey.id)
  end

  defp insert_respondents(survey, channel, mode, phone_numbers) do
    phone_numbers = RespondentGroupAction.loaded_phone_numbers(phone_numbers)
    group = RespondentGroupAction.create(UUID.uuid4(), phone_numbers, survey)
    RespondentGroupAction.update_channels(group.id, [%{"id" => channel.id, "mode" => mode}])
  end

  defp set_one_respondent_disposition(survey, disposition) do
    survey
    |> assoc(:respondents)
    |> limit(1)
    |> Repo.one!()
    |> Respondent.changeset(%{disposition: disposition})
    |> Repo.update!()
  end

  defp respondent_in_survey?(survey, hashed_number) do
    respondent =
      survey
      |> assoc(:respondents)
      |> Repo.get_by(hashed_number: hashed_number)

    !!respondent
  end

  defp assert_repeated_without_respondent(latest_occurrence, new_occurrence, unpromoted_respondent) do
    assert respondent_in_survey?(latest_occurrence, unpromoted_respondent.hashed_number)
    refute respondent_in_survey?(new_occurrence, unpromoted_respondent.hashed_number)
  end
end
