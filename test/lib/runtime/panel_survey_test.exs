defmodule Ask.Runtime.PanelSurveyTest do
  use Ask.ModelCase
  use Ask.TestHelpers
  use Ask.MockTime
  alias Ask.Runtime.PanelSurvey
  alias Ask.{Survey, Repo, Respondent}

  describe "new_occurrence/1" do
    test "creates a new ready occurrence" do
      panel_survey = panel_survey_with_last_occurrence_terminated()

      {result, data} = PanelSurvey.new_occurrence(panel_survey)

      assert result == :ok
      new_occurrence = Map.get(data, :new_occurrence)
      assert new_occurrence
      assert new_occurrence.state == "ready"
      assert new_occurrence.panel_survey_id == panel_survey.id
    end

    # TODO: test different survey configurations
    test "preserves the basic settings" do
      panel_survey = completed_panel_survey_with_respondents()
      latest_occurrence = Ask.PanelSurvey.latest_occurrence(panel_survey)

      {:ok, %{new_occurrence: new_occurrence}} = PanelSurvey.new_occurrence(panel_survey)

      assert new_occurrence.project_id == panel_survey.project_id
      assert new_occurrence.project_id == latest_occurrence.project_id
      assert new_occurrence.folder_id == latest_occurrence.folder_id
      assert new_occurrence.description == latest_occurrence.description
      assert new_occurrence.mode == latest_occurrence.mode
      refute new_occurrence.started_at == latest_occurrence.started_at
      refute latest_occurrence.started_at
      assert new_occurrence.panel_survey_id == latest_occurrence.panel_survey_id
    end

    @tag :time_mock
    test "renew the new occurrence name" do
      now = Timex.parse!("2021-06-14T09:00:00Z", "{ISO:Extended}")
      mock_time(now)
      expected_occurrence_name = "2021-06-14"
      panel_survey = completed_panel_survey_with_respondents()

      {:ok, %{new_occurrence: new_occurrence}} = PanelSurvey.new_occurrence(panel_survey)

      assert new_occurrence.name == expected_occurrence_name
    end

    # TODO: test different survey configurations
    test "preserves the advanced settings" do
      panel_survey = completed_panel_survey_with_respondents()
      latest_occurrence = Ask.PanelSurvey.latest_occurrence(panel_survey)

      {:ok, %{new_occurrence: new_occurrence}} = PanelSurvey.new_occurrence(panel_survey)

      assert new_occurrence.cutoff == latest_occurrence.cutoff
      assert new_occurrence.count_partial_results == latest_occurrence.count_partial_results
      assert new_occurrence.sms_retry_configuration == latest_occurrence.sms_retry_configuration
      assert new_occurrence.ivr_retry_configuration == latest_occurrence.ivr_retry_configuration
      assert new_occurrence.mobileweb_retry_configuration == latest_occurrence.mobileweb_retry_configuration
      assert new_occurrence.fallback_delay == latest_occurrence.fallback_delay
      assert new_occurrence.quota_vars == latest_occurrence.quota_vars
      assert new_occurrence.quotas == latest_occurrence.quotas
    end

    test "preserves every respondent with their hashed phone number and mode/channel associations" do
      panel_survey = completed_panel_survey_with_respondents()
      latest_occurrence = Ask.PanelSurvey.latest_occurrence(panel_survey)

      {:ok, %{new_occurrence: new_occurrence}} = PanelSurvey.new_occurrence(panel_survey)

      assert respondent_channels(latest_occurrence) == respondent_channels(new_occurrence)
    end

    test "doesn't promote the refused respondents" do
      panel_survey = completed_panel_survey_with_respondents()
      latest_occurrence = Ask.PanelSurvey.latest_occurrence(panel_survey)
      refused_respondent = set_one_respondent_disposition(latest_occurrence, "refused")

      {:ok, %{new_occurrence: new_occurrence}} = PanelSurvey.new_occurrence(panel_survey)

      assert_repeated_without_respondent(latest_occurrence, new_occurrence, refused_respondent)
    end

    test "doesn't promote the ineligible respondents" do
      panel_survey = completed_panel_survey_with_respondents()
      latest_occurrence = Ask.PanelSurvey.latest_occurrence(panel_survey)
      ineligible_respondent = set_one_respondent_disposition(latest_occurrence, "ineligible")

      {:ok, %{new_occurrence: new_occurrence}} = PanelSurvey.new_occurrence(panel_survey)

      assert_repeated_without_respondent(latest_occurrence, new_occurrence, ineligible_respondent)
    end

    test "preserves the incentives enabled flag" do
      panel_survey = incentives_enabled_panel_survey()

      {:ok, %{new_occurrence: new_occurrence}} = PanelSurvey.new_occurrence(panel_survey)

      assert_incentives_enabled(new_occurrence)

      panel_survey = incentives_disabled_panel_survey()

      {:ok, %{new_occurrence: new_occurrence}} = PanelSurvey.new_occurrence(panel_survey)

      assert_incentives_disabled(new_occurrence)
    end

    test "removes start_date and end_date of the schedule" do
      panel_survey = scheduled_panel_survey()
      schedule = Ask.PanelSurvey.latest_occurrence(panel_survey).schedule

      {:ok, %{new_occurrence: new_occurrence}} = PanelSurvey.new_occurrence(panel_survey)

      assert new_occurrence.schedule ==
        clean_dates(schedule)
    end

    test "errors when the latest ocurrence isn't terminated" do
      panel_survey = panel_survey_with_occurrence()

      {result, data} = PanelSurvey.new_occurrence(panel_survey)

      assert result == :error
      assert Map.get(data, :error) == "Last panel survey occurrence isn't terminated"
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

  defp incentives_enabled_panel_survey() do
    panel_survey_with_last_occurrence_terminated()
  end

  defp incentives_disabled_panel_survey() do
    panel_survey =
      panel_survey_with_last_occurrence_terminated()

    Ask.PanelSurvey.latest_occurrence(panel_survey)
    |> disable_incentives()

    # Reload the panel survey. One of its surveys has changed, so it's outdated
    Repo.get!(Ask.PanelSurvey, panel_survey.id)
  end

  defp scheduled_panel_survey() do
    panel_survey = panel_survey_with_last_occurrence_terminated()
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
