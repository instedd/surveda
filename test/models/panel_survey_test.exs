defmodule Ask.PanelSurveyTest do
  use Ask.ModelCase
  use Ask.MockTime
  use Ask.TestHelpers
  alias Ask.{PanelSurvey, Repo}

  describe "create_panel_survey/1" do
    test "with valid data creates a panel_survey" do
      survey = panel_survey_generator_survey()

      {result, panel_survey} =
        PanelSurvey.create_panel_survey_from_survey(survey)

      assert result == :ok
      assert panel_survey.project_id == survey.project_id
    end

    test "takes the name from its first occurence" do
      survey = panel_survey_generator_survey()
      expected_name = survey.name

      {:ok, panel_survey} =
        PanelSurvey.create_panel_survey_from_survey(survey)

      assert panel_survey.name == expected_name
    end

    test "it's created from its first occurrence" do
      survey = panel_survey_generator_survey()

      {:ok, panel_survey} =
        PanelSurvey.create_panel_survey_from_survey(survey)

      occurrences = Repo.preload(panel_survey, :occurrences).occurrences
      assert length(occurrences) == 1
      [first_occurrence] = occurrences
      assert first_occurrence.id == survey.id
    end

    @tag :time_mock
    test "renames its first occurence to YYYY-MM-DD" do
      now = Timex.parse!("2021-06-17T09:00:00Z", "{ISO:Extended}")
      mock_time(now)
      survey = panel_survey_generator_survey()
      expected_occurrence_name = "2021-06-17"

      {:ok, _panel_survey} =
        PanelSurvey.create_panel_survey_from_survey(survey)

      survey = Repo.get!(Survey, survey.id)
      assert survey.name == expected_occurrence_name
    end

    test "takes the folder from its first occurence" do
      survey = panel_survey_generator_survey_in_folder()

      {result, panel_survey} =
        PanelSurvey.create_panel_survey_from_survey(survey)

      assert result == :ok
      # Assert the panel survey takes its folder from the survey
      assert panel_survey.folder_id == survey.folder_id
      # The survey occurrence doesn't belong to the folder. Its panel survey does.
      # Assert the survey was removed from its folder
      survey = Repo.get!(Survey, survey.id)
      refute survey.folder_id
    end

    test "rejects creating a panel survey when the survey generates_panel_survey flag is OFF" do
      survey = panel_survey_generator_survey()
      |> Survey.changeset(%{generates_panel_survey: false})
      |> Repo.update!()

      {result, error} =
        PanelSurvey.create_panel_survey_from_survey(survey)

      assert result == :error
      assert error == "Survey must have generates_panel_survey ON to launch to generate a panel survey"
    end

    test "rejects creating a panel survey when the survey isn't ready to launch" do
      survey = panel_survey_generator_survey()
      |> Survey.changeset(%{state: "not_ready"})
      |> Repo.update!()

      {result, error} =
        PanelSurvey.create_panel_survey_from_survey(survey)

      assert result == :error
      assert error == "Survey must be ready to launch to generate a panel survey"
    end

    test "rejects creating a panel survey when the survey is a panel survey occurrence" do
      panel_survey = dummy_panel_survey()
      survey = panel_survey_generator_survey()
      |> Survey.changeset(%{panel_survey_id: panel_survey.id})
      |> Repo.update!()

      {result, error} =
        PanelSurvey.create_panel_survey_from_survey(survey)

      assert result == :error
      assert error == "Survey can't be a panel survey occurence to generate a panel survey"
    end

    @tag :time_mock
    test "when the survey doesn't have a name it's named `Panel Survey YYYY-MM-DD`" do
      Timex.parse!("2021-06-17T09:00:00Z", "{ISO:Extended}")
      |> mock_time()
      expected_name = "Panel Survey 2021-06-17"
      project = insert(:project)
      survey = insert(:survey, project: project, generates_panel_survey: true, state: "ready", name: nil)

      {result, panel_survey} = PanelSurvey.create_panel_survey_from_survey(survey)

      assert result == :ok
      assert panel_survey.name == expected_name
    end
  end

  describe "list_panel_surveys/0" do
    test "returns all panel_surveys" do
      panel_survey = dummy_panel_survey()

      listed_panel_surveys = PanelSurvey.list_panel_surveys()

      assert listed_panel_surveys == [panel_survey]
    end
  end

  describe "get_panel_survey!/1" do
    test "returns the panel_survey with given id" do
      panel_survey = dummy_panel_survey()

      loaded_panel_survey = PanelSurvey.get_panel_survey!(panel_survey.id)

      assert loaded_panel_survey == panel_survey
    end
  end

  describe "update_panel_survey/2" do
    test "with valid data updates the panel_survey (name)" do
      panel_survey = dummy_panel_survey()
      updated_name = @bar_string
      update_attrs = %{name: updated_name}

      {result, updated_panel_survey} = PanelSurvey.update_panel_survey(panel_survey, update_attrs)

      # The right panel survey was updated
      assert result == :ok
      assert panel_survey.id == updated_panel_survey.id

      # The name was updated
      refute panel_survey.name == updated_panel_survey.name
      assert updated_panel_survey.name == updated_name
    end

    test "with valid data updates the panel_survey (folder)" do
      panel_survey = dummy_panel_survey_in_folder()
      updated_folder = insert(:folder)
      update_attrs = %{folder_id: updated_folder.id}

      {result, updated_panel_survey} = PanelSurvey.update_panel_survey(panel_survey, update_attrs)

      # The right panel survey was updated
      assert result == :ok
      assert panel_survey.id == updated_panel_survey.id

      # The folder_id was updated
      refute panel_survey.folder_id == updated_panel_survey.folder_id
      assert updated_panel_survey.folder_id == updated_folder.id

      # The associated folder was updated
      panel_survey = Repo.preload(panel_survey, :folder)
      updated_panel_survey = Repo.preload(updated_panel_survey, folder: :project)
      refute panel_survey.folder == updated_panel_survey.folder
      assert updated_panel_survey.folder == updated_folder
    end

    test "with valid data sets a panel_survey folder" do
      panel_survey = dummy_panel_survey()
      folder = insert(:folder)
      update_attrs = %{folder_id: folder.id}

      {result, updated_panel_survey} = PanelSurvey.update_panel_survey(panel_survey, update_attrs)

      # The right panel survey was updated
      assert result == :ok
      assert panel_survey.id == updated_panel_survey.id

      # The folder_id was set
      refute panel_survey.folder_id
      assert updated_panel_survey.folder_id == folder.id

      # The associated folder was set
      panel_survey = Repo.preload(panel_survey, :folder)
      refute panel_survey.folder
      updated_panel_survey = Repo.preload(updated_panel_survey, folder: :project)
      assert updated_panel_survey.folder == folder
    end

    test "update_panel_survey/2 with valid data unsets the panel_survey folder" do
      panel_survey = dummy_panel_survey_in_folder()
      update_attrs = %{folder_id: nil}

      {result, updated_panel_survey} = PanelSurvey.update_panel_survey(panel_survey, update_attrs)

      # The right panel survey was updated
      assert result == :ok
      assert panel_survey.id == updated_panel_survey.id

      # The folder_id was unset
      assert panel_survey.folder_id
      refute updated_panel_survey.folder_id

      # The associated folder was unset
      panel_survey = Repo.preload(panel_survey, :folder)
      assert panel_survey.folder
      updated_panel_survey = Repo.preload(updated_panel_survey, :folder)
      refute updated_panel_survey.folder
    end

    test "doesn't updates the panel_survey project (with valid data)" do
      panel_survey = dummy_panel_survey()
      updated_project = insert(:project)
      update_attrs = %{project_id: updated_project.id}

      {result, error} = PanelSurvey.update_panel_survey(panel_survey, update_attrs)

      assert_project_cant_be_changed(result, error, panel_survey)
    end

    test "doesn't updates the panel_survey project (with invvalid data)" do
      panel_survey = dummy_panel_survey()
      invalid_attrs = %{project_id: nil}

      {result, error} = PanelSurvey.update_panel_survey(panel_survey, invalid_attrs)

      assert_project_cant_be_changed(result, error, panel_survey)
    end

    test "with invalid data returns error changeset (nil name)" do
      panel_survey = dummy_panel_survey()
      invalid_attrs = %{name: nil}

      {result, changeset} = PanelSurvey.update_panel_survey(panel_survey, invalid_attrs)

      assert result == :error

      assert changeset.action == :update
      assert changeset.changes == %{name: nil}
      assert changeset.valid? == false
      assert changeset.errors == [name: {"can't be blank", [validation: :required]}]
      assert_panel_survey_didn_changed(panel_survey)
    end
  end

  describe "delete_panel_survey/1" do
    test "deletes the panel_survey" do
      panel_survey = dummy_panel_survey()

      {result, deleted_panel_survey} = PanelSurvey.delete_panel_survey(panel_survey)

      # The right panel survey was deleted
      assert result == :ok
      assert deleted_panel_survey.id == panel_survey.id

      # The panel survey was actually deleted
      assert panel_survey.__meta__.state == :loaded
      assert deleted_panel_survey.__meta__.state == :deleted
      assert_raise Ecto.NoResultsError, fn -> PanelSurvey.get_panel_survey!(panel_survey.id) end
    end

    test "deletes the panel_survey inside folder" do
      panel_survey = dummy_panel_survey_in_folder()

      {result, deleted_panel_survey} = PanelSurvey.delete_panel_survey(panel_survey)

      # The right panel survey was deleted
      assert result == :ok
      assert deleted_panel_survey.id == panel_survey.id

      # The panel survey was actually deleted
      assert panel_survey.__meta__.state == :loaded
      assert deleted_panel_survey.__meta__.state == :deleted
      assert_raise Ecto.NoResultsError, fn -> PanelSurvey.get_panel_survey!(panel_survey.id) end
    end
  end

  describe "repeatable?/1" do
    test "returns true when the panel survey is repeatable" do
      panel_survey = completed_panel_survey_with_respondents()

      repeatable_survey? = PanelSurvey.repeatable?(panel_survey)

      assert repeatable_survey? == true
    end

    test "returns false when the panel survey isn't repeatable" do
      panel_survey = dummy_panel_survey()

      repeatable_survey? = PanelSurvey.repeatable?(panel_survey)

      assert repeatable_survey? == false
    end
  end

  defp assert_panel_survey_didn_changed(panel_survey) do
    assert panel_survey == Repo.get!(PanelSurvey, panel_survey.id)
  end

  defp assert_project_cant_be_changed(result, error, panel_survey) do
    assert result == :error
    assert error == "Project can't be changed"
    assert_panel_survey_didn_changed(panel_survey)
  end
end
