defmodule Ask.Runtime.SurveyActionTest do
  use Ask.ModelCase
  use Ask.MockTime
  alias Ask.Runtime.SurveyAction
  alias Ask.Survey

  describe "start/1" do

    test "generates a panel survey if generates_panel_survey is ON" do
      survey = panel_survey_generator_survey()

      {:ok, %{survey: survey}} = SurveyAction.start(survey)

      assert survey.panel_survey_id
    end

    test "names the generated panel survey with the survey name" do
      survey = panel_survey_generator_survey()
      expected_panel_survey_name = survey.name

      {:ok, %{survey: survey}} = SurveyAction.start(survey)

      panel_survey = Repo.preload(survey, :panel_survey).panel_survey
      assert panel_survey.name == expected_panel_survey_name
    end

    @tag :time_mock
    test "rename the survey to YYYY-MM-dd" do
      now = Timex.parse!("2021-06-14T09:00:00Z", "{ISO:Extended}")
      mock_time(now)
      survey = panel_survey_generator_survey()
      expected_survey_name = "2021-06-14"

      {:ok, %{survey: survey}} = SurveyAction.start(survey)

      assert survey.name == expected_survey_name
    end

    test "pass the survey folder to its panel survey" do
      survey = panel_survey_generator_survey_with_folder()
      expected_folder_id = survey.folder_id

      {:ok, %{survey: survey}} = SurveyAction.start(survey)

      survey = Repo.preload(survey, :panel_survey)
      panel_survey = survey.panel_survey
      refute survey.folder_id
      assert panel_survey.folder_id
      assert panel_survey.folder_id == expected_folder_id
    end

    test "doesn't generate a panel survey when generates_panel_survey is OFF" do
      survey = ready_survey()

      {:ok, %{survey: survey}} = SurveyAction.start(survey)

      refute survey.panel_survey_id
    end

    test "doesn't rename the survey" do
      survey = ready_survey()
      expected_survey_name = survey.name

      {:ok, %{survey: survey}} = SurveyAction.start(survey)

      assert survey.name == expected_survey_name
    end

    test "doesn't remove the survey from folder" do
      survey = ready_survey_in_folder()
      expected_folder_id = survey.folder_id

      {:ok, %{survey: survey}} = SurveyAction.start(survey)

      assert survey.folder_id
      assert survey.folder_id == expected_folder_id
    end
  end

  defp ready_survey() do
    project = insert(:project)
    insert(:survey, state: "ready", project: project)
  end

  defp ready_survey_in_folder() do
    project = insert(:project)
    insert(:survey, state: "ready", project: project)
    |> include_in_folder(project)
  end

  defp panel_survey_generator_survey() do
    project = insert(:project)
    insert(:survey, state: "ready", project: project, generates_panel_survey: true)
  end

  defp panel_survey_generator_survey_with_folder() do
    project = insert(:project)
    insert(:survey, state: "ready", project: project, generates_panel_survey: true)
    |> include_in_folder(project)
  end

  defp include_in_folder(survey, project) do
    folder = insert(:folder, project: project)
    Survey.changeset(survey, %{folder_id: folder.id})
    |> Repo.update!()
  end
end
