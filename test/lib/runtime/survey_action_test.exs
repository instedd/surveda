defmodule Ask.SurveyActionTest do
  use Ask.ModelCase
  alias Ask.Runtime.SurveyAction
  alias Ask.{Survey, Repo, TestChannel, Respondent}

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
    Survey.changeset(survey, %{panel_survey_of: regular_survey().id, latest_panel_survey: true})
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

  defp repeated_survey() do
    survey = completed_panel_survey()
    SurveyAction.repeat(survey)
    Repo.get!(Survey, survey.id)
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
    group = Ask.Runtime.RespondentGroup.create(UUID.uuid4(), phone_numbers, survey)
    Ask.Runtime.RespondentGroup.update_channels(group.id, [%{"id" => channel.id, "mode" => mode}])
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
end
