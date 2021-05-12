defmodule Ask.PanelSurveyTest do
  use Ask.ModelCase
  alias Ask.{PanelSurvey, Repo}

  @foo_string "foo"
  @bar_string "bar"

  test "create_panel_survey/1 with valid data creates a panel_survey" do
    project = insert(:project)
    name = @foo_string

    {result, panel_survey} =
      PanelSurvey.create_panel_survey(%{name: name, project_id: project.id})

    assert result == :ok
    assert panel_survey.name == name
    assert panel_survey.project_id == project.id
    panel_survey = Repo.preload(panel_survey, :project)
    assert panel_survey.project == project
  end


  test "create_panel_survey/1 with valid data creates a panel_survey inside a folder" do
    project = insert(:project)
    folder = insert(:folder, project: project)
    name = @foo_string

    {result, panel_survey} =
      PanelSurvey.create_panel_survey(%{name: name, project_id: project.id, folder_id: folder.id})

    assert result == :ok
    assert panel_survey.folder_id == folder.id
    panel_survey = Repo.preload(panel_survey, [folder: :project])
    assert panel_survey.folder == folder
  end

  test "list_panel_surveys/0 returns all panel_surveys" do
    panel_survey = dummy_panel_survey()

    listed_panel_surveys = PanelSurvey.list_panel_surveys()

    assert listed_panel_surveys == [panel_survey]
  end

  test "get_panel_survey!/1 returns the panel_survey with given id" do
    panel_survey = dummy_panel_survey()

    loaded_panel_survey = PanelSurvey.get_panel_survey!(panel_survey.id)

    assert loaded_panel_survey == panel_survey
  end

  test "create_panel_survey/1 with invalid data returns error changeset (no name)" do
    project = insert(:project)
    invalid_attrs = %{project_id: project.id}

    {result, changeset} = PanelSurvey.create_panel_survey(invalid_attrs)

    assert result == :error
    assert changeset.action == :insert
    assert changeset.changes == %{project_id: project.id}
    assert changeset.valid? == false
    assert changeset.errors == [name: {"can't be blank", [validation: :required]}]
  end

  test "create_panel_survey/1 with invalid data returns error changeset (no project)" do
    name = @foo_string
    invalid_attrs = %{name: name}

    {result, changeset} = PanelSurvey.create_panel_survey(invalid_attrs)

    assert result == :error
    assert changeset.action == :insert
    assert changeset.changes == %{name: "foo"}
    assert changeset.valid? == false
    assert changeset.errors == [project_id: {"can't be blank", [validation: :required]}]
  end

  test "update_panel_survey/2 with valid data updates the panel_survey (name)" do
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

  test "update_panel_survey/2 with valid data updates the panel_survey (project)" do
    panel_survey = dummy_panel_survey()
    updated_project = insert(:project)
    update_attrs = %{project_id: updated_project.id}

    {result, updated_panel_survey} = PanelSurvey.update_panel_survey(panel_survey, update_attrs)

    # The right panel survey was updated
    assert result == :ok
    assert panel_survey.id == updated_panel_survey.id

    # The project_id was updated
    refute panel_survey.project_id == updated_panel_survey.project_id
    assert updated_panel_survey.project_id == updated_project.id

    # The associated project was updated
    panel_survey = Repo.preload(panel_survey, :project)
    updated_panel_survey = Repo.preload(updated_panel_survey, :project)
    refute panel_survey.project == updated_panel_survey.project
    assert updated_panel_survey.project == updated_project
  end

  test "update_panel_survey/2 with valid data updates the panel_survey (folder)" do
    panel_survey = dummy_panel_survey_inside_folder()
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

  test "update_panel_survey/2 with valid data sets a panel_survey folder" do
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
    panel_survey = dummy_panel_survey_inside_folder()
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

  test "update_panel_survey/2 with invalid data returns error changeset (nil project)" do
    panel_survey = dummy_panel_survey()
    invalid_attrs = %{project_id: nil}

    {result, changeset} = PanelSurvey.update_panel_survey(panel_survey, invalid_attrs)

    assert result == :error

    assert changeset.action == :update
    assert changeset.changes == %{project_id: nil}
    assert changeset.valid? == false
    assert changeset.errors == [project_id: {"can't be blank", [validation: :required]}]
  end

  test "update_panel_survey/2 with invalid data returns error changeset (nil name)" do
    panel_survey = dummy_panel_survey()
    invalid_attrs = %{name: nil}

    {result, changeset} = PanelSurvey.update_panel_survey(panel_survey, invalid_attrs)

    assert result == :error

    assert changeset.action == :update
    assert changeset.changes == %{name: nil}
    assert changeset.valid? == false
    assert changeset.errors == [name: {"can't be blank", [validation: :required]}]
  end

  test "delete_panel_survey/1 deletes the panel_survey" do
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

  test "delete_panel_survey/1 deletes the panel_survey inside folder" do
    panel_survey = dummy_panel_survey_inside_folder()

    {result, deleted_panel_survey} = PanelSurvey.delete_panel_survey(panel_survey)

    # The right panel survey was deleted
    assert result == :ok
    assert deleted_panel_survey.id == panel_survey.id

    # The panel survey was actually deleted
    assert panel_survey.__meta__.state == :loaded
    assert deleted_panel_survey.__meta__.state == :deleted
    assert_raise Ecto.NoResultsError, fn -> PanelSurvey.get_panel_survey!(panel_survey.id) end
  end

  test "change_panel_survey/1 returns a panel_survey changeset" do
    panel_survey = dummy_panel_survey()
    assert %Ecto.Changeset{} = PanelSurvey.change_panel_survey(panel_survey)
  end

  defp dummy_panel_survey() do
    project = insert(:project)
    name = @foo_string

    {:ok, panel_survey} = PanelSurvey.create_panel_survey(%{name: name, project_id: project.id})

    panel_survey
  end

  defp dummy_panel_survey_inside_folder() do
    project = insert(:project)
    name = @foo_string
    folder = insert(:folder)
    {:ok, panel_survey} = PanelSurvey.create_panel_survey(%{name: name, project_id: project.id, folder_id: folder.id})

    panel_survey
  end
end
