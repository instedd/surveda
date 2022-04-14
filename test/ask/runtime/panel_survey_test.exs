defmodule Ask.Runtime.PanelSurveyTest do
  use Ask.DataCase
  use Ask.TestHelpers
  use Ask.MockTime
  alias Ask.Runtime.PanelSurvey
  alias Ask.{Survey, Repo, Respondent}

  describe "new_wave/1" do
    test "creates a new ready wave" do
      panel_survey = panel_survey_with_last_wave_terminated()

      {result, data} = PanelSurvey.new_wave(panel_survey)

      assert result == :ok
      new_wave = Map.get(data, :new_wave)
      assert new_wave
      assert new_wave.state == "ready"
      assert new_wave.panel_survey_id == panel_survey.id
    end

    # TODO: test different survey configurations
    test "preserves the basic settings" do
      panel_survey = completed_panel_survey_with_respondents()
      latest_wave = Ask.PanelSurvey.latest_wave(panel_survey)

      {:ok, %{new_wave: new_wave}} = PanelSurvey.new_wave(panel_survey)

      assert new_wave.project_id == panel_survey.project_id
      assert new_wave.project_id == latest_wave.project_id
      assert new_wave.folder_id == latest_wave.folder_id
      assert new_wave.description == latest_wave.description
      assert new_wave.mode == latest_wave.mode
      refute new_wave.started_at == latest_wave.started_at
      refute latest_wave.started_at
      assert new_wave.panel_survey_id == latest_wave.panel_survey_id
    end

    @tag :time_mock
    test "renew the new wave name" do
      now = Timex.parse!("2021-06-14T09:00:00Z", "{ISO:Extended}")
      mock_time(now)
      expected_wave_name = "2021-06-14"
      panel_survey = completed_panel_survey_with_respondents()

      {:ok, %{new_wave: new_wave}} = PanelSurvey.new_wave(panel_survey)

      assert new_wave.name == expected_wave_name
    end

    # TODO: test different survey configurations
    test "preserves the advanced settings" do
      panel_survey = completed_panel_survey_with_respondents()
      latest_wave = Ask.PanelSurvey.latest_wave(panel_survey)

      {:ok, %{new_wave: new_wave}} = PanelSurvey.new_wave(panel_survey)

      assert new_wave.cutoff == latest_wave.cutoff
      assert new_wave.count_partial_results == latest_wave.count_partial_results
      assert new_wave.sms_retry_configuration == latest_wave.sms_retry_configuration
      assert new_wave.ivr_retry_configuration == latest_wave.ivr_retry_configuration
      assert new_wave.mobileweb_retry_configuration == latest_wave.mobileweb_retry_configuration
      assert new_wave.fallback_delay == latest_wave.fallback_delay
      assert new_wave.quota_vars == latest_wave.quota_vars
      assert new_wave.quotas == latest_wave.quotas
    end

    test "preserves every respondent with their hashed phone number and mode/channel associations" do
      panel_survey = completed_panel_survey_with_respondents()
      latest_wave = Ask.PanelSurvey.latest_wave(panel_survey)

      {:ok, %{new_wave: new_wave}} = PanelSurvey.new_wave(panel_survey)

      assert respondent_channels(latest_wave) == respondent_channels(new_wave)
    end

    test "doesn't promote the refused respondents" do
      panel_survey = completed_panel_survey_with_respondents()
      latest_wave = Ask.PanelSurvey.latest_wave(panel_survey)
      refused_respondent = set_one_respondent_disposition(latest_wave, "refused")

      {:ok, %{new_wave: new_wave}} = PanelSurvey.new_wave(panel_survey)

      assert_repeated_without_respondent(latest_wave, new_wave, refused_respondent)
    end

    test "doesn't promote the ineligible respondents" do
      panel_survey = completed_panel_survey_with_respondents()
      latest_wave = Ask.PanelSurvey.latest_wave(panel_survey)
      ineligible_respondent = set_one_respondent_disposition(latest_wave, "ineligible")

      {:ok, %{new_wave: new_wave}} = PanelSurvey.new_wave(panel_survey)

      assert_repeated_without_respondent(latest_wave, new_wave, ineligible_respondent)
    end

    test "preserves the incentives enabled flag" do
      panel_survey = incentives_enabled_panel_survey()

      {:ok, %{new_wave: new_wave}} = PanelSurvey.new_wave(panel_survey)

      assert_incentives_enabled(new_wave)

      panel_survey = incentives_disabled_panel_survey()

      {:ok, %{new_wave: new_wave}} = PanelSurvey.new_wave(panel_survey)

      assert_incentives_disabled(new_wave)
    end

    test "removes start_date and end_date of the schedule" do
      panel_survey = scheduled_panel_survey()
      schedule = Ask.PanelSurvey.latest_wave(panel_survey).schedule

      {:ok, %{new_wave: new_wave}} = PanelSurvey.new_wave(panel_survey)

      assert new_wave.schedule ==
               clean_dates(schedule)
    end

    test "errors when the latest wave isn't terminated" do
      panel_survey = panel_survey_with_wave()

      {result, data} = PanelSurvey.new_wave(panel_survey)

      assert result == :error
      assert Map.get(data, :error) == "Last panel survey wave isn't terminated"
    end
  end

  describe "create_panel_survey_from_survey/1" do
    test "with valid data creates a panel_survey" do
      survey = panel_survey_generator_survey()

      {result, panel_survey} = PanelSurvey.create_panel_survey_from_survey(survey)

      assert result == :ok
      assert panel_survey.project_id == survey.project_id
    end

    test "takes the name from its first wave" do
      survey = panel_survey_generator_survey()
      expected_name = survey.name

      {:ok, panel_survey} = PanelSurvey.create_panel_survey_from_survey(survey)

      assert panel_survey.name == expected_name
    end

    test "it's created from its first wave" do
      survey = panel_survey_generator_survey()

      {:ok, panel_survey} = PanelSurvey.create_panel_survey_from_survey(survey)

      waves = Repo.preload(panel_survey, :waves).waves
      assert length(waves) == 1
      [first_wave] = waves
      assert first_wave.id == survey.id
    end

    @tag :time_mock
    test "renames its first wave to YYYY-MM-DD" do
      now = Timex.parse!("2021-06-17T09:00:00Z", "{ISO:Extended}")
      mock_time(now)
      survey = panel_survey_generator_survey()
      expected_wave_name = "2021-06-17"

      {:ok, _panel_survey} = PanelSurvey.create_panel_survey_from_survey(survey)

      survey = Repo.get!(Survey, survey.id)
      assert survey.name == expected_wave_name
    end

    test "takes the folder from its first wave" do
      survey = panel_survey_generator_survey_in_folder()

      {:ok, panel_survey} = PanelSurvey.create_panel_survey_from_survey(survey)

      # Assert the panel survey takes its folder from the survey
      assert panel_survey.folder_id == survey.folder_id
      # The survey wave doesn't belong to the folder. Its panel survey does.
      # Assert the survey was removed from its folder
      survey = Repo.get!(Survey, survey.id)
      refute survey.folder_id
    end

    test "removes the cutoff and comparisons" do
      survey = panel_survey_generator_survey_with_cutoff_and_comparisons()

      {:ok, panel_survey} = PanelSurvey.create_panel_survey_from_survey(survey)

      assert_panel_survey_without_cutoff_and_comparisons(panel_survey)
    end

    test "rejects creating a panel survey when the survey generates_panel_survey flag is OFF" do
      survey =
        panel_survey_generator_survey()
        |> Survey.changeset(%{generates_panel_survey: false})
        |> Repo.update!()

      {result, error} = PanelSurvey.create_panel_survey_from_survey(survey)

      assert result == :error

      assert error ==
               "Survey must have generates_panel_survey ON to launch to generate a panel survey"
    end

    test "rejects creating a panel survey when the survey isn't ready to launch" do
      survey =
        panel_survey_generator_survey()
        |> Survey.changeset(%{state: "not_ready"})
        |> Repo.update!()

      {result, error} = PanelSurvey.create_panel_survey_from_survey(survey)

      assert result == :error
      assert error == "Survey must be ready to launch to generate a panel survey"
    end

    test "rejects creating a panel survey when the survey is a panel survey wave" do
      panel_survey = dummy_panel_survey()

      survey =
        panel_survey_generator_survey()
        |> Survey.changeset(%{panel_survey_id: panel_survey.id})
        |> Repo.update!()

      {result, error} = PanelSurvey.create_panel_survey_from_survey(survey)

      assert result == :error
      assert error == "Survey can't be a panel survey wave to generate a panel survey"
    end

    @tag :time_mock
    test "when the survey doesn't have a name it's named `Panel Survey YYYY-MM-DD`" do
      Timex.parse!("2021-06-17T09:00:00Z", "{ISO:Extended}")
      |> mock_time()

      expected_name = "Panel Survey 2021-06-17"
      project = insert(:project)

      survey =
        insert(:survey, project: project, generates_panel_survey: true, state: "ready", name: nil)

      {result, panel_survey} = PanelSurvey.create_panel_survey_from_survey(survey)

      assert result == :ok
      assert panel_survey.name == expected_name
    end
  end

  defp respondent_channels(survey) do
    survey =
      survey
      |> Repo.preload(respondents: [respondent_group: [respondent_group_channels: :channel]])

    respondent_channels =
      Enum.map(survey.respondents, fn %{
                                        hashed_number: hashed_number,
                                        respondent_group: respondent_group
                                      } ->
        respondent_group_channels =
          Enum.map(respondent_group.respondent_group_channels, fn %{channel: channel, mode: mode} ->
            %{channel_id: channel.id, mode: mode}
          end)

        {hashed_number, respondent_group_channels}
      end)

    # We sort the response by hashed_number so that the function
    # is deterministic enough to be used to compare lists using ==
    List.keysort(respondent_channels, 0)
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
    panel_survey_with_last_wave_terminated()
  end

  defp incentives_disabled_panel_survey() do
    panel_survey = panel_survey_with_last_wave_terminated()

    Ask.PanelSurvey.latest_wave(panel_survey)
    |> disable_incentives()

    # Reload the panel survey. One of its surveys has changed, so it's outdated
    Repo.get!(Ask.PanelSurvey, panel_survey.id)
  end

  defp scheduled_panel_survey() do
    panel_survey = panel_survey_with_last_wave_terminated()
    latest_wave = Ask.PanelSurvey.latest_wave(panel_survey)
    start_date = ~D[2016-01-01]
    end_date = ~D[2016-02-01]

    schedule =
      set_start_date(latest_wave.schedule, start_date)
      |> set_end_date(end_date)

    set_schedule(latest_wave, schedule)

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

  defp assert_repeated_without_respondent(latest_wave, new_wave, unpromoted_respondent) do
    assert respondent_in_survey?(latest_wave, unpromoted_respondent.hashed_number)
    refute respondent_in_survey?(new_wave, unpromoted_respondent.hashed_number)
  end

  defp assert_panel_survey_without_cutoff_and_comparisons(panel_survey) do
    latest = Ask.PanelSurvey.latest_wave(panel_survey)
    assert latest.comparisons == []
    assert latest.quota_vars == []
    assert latest.cutoff == nil
    assert latest.count_partial_results == false
  end
end
