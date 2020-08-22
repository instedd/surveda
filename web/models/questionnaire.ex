defmodule Ask.Questionnaire do
  use Ask.Web, :model

  alias Ask.{Questionnaire, QuestionnaireVariable, ActivityLog, Repo}
  alias Ask.Ecto.Type.JSON
  alias Ecto.Multi

  schema "questionnaires" do
    field :name, :string
    field :description, :string
    field :modes, Ask.Ecto.Type.StringList
    field :steps, JSON
    field :quota_completed_steps, JSON
    field :settings, JSON
    field :languages, JSON
    field :default_language, :string
    field :valid, :boolean
    field :deleted, :boolean
    field :partial_relevant_config, JSON
    belongs_to :snapshot_of_questionnaire, Ask.Questionnaire, foreign_key: :snapshot_of
    belongs_to :project, Ask.Project
    has_many :questionnaire_variables, Ask.QuestionnaireVariable, on_delete: :delete_all
    has_many :translations, Ask.Translation, on_delete: :delete_all

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:project_id, :name, :description, :modes, :steps, :quota_completed_steps, :languages, :default_language, :valid, :settings, :snapshot_of, :deleted, :partial_relevant_config])
    |> validate_required([:project_id, :modes, :steps, :settings])
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:snapshot_of)
  end

  def recreate_variables!(questionnaire) do
    # Get existing variables
    existing_variables = (from v in QuestionnaireVariable,
      where: v.questionnaire_id == ^questionnaire.id)
    |> Repo.all

    # Get new names
    new_names = questionnaire
    |> all_steps
    |> Enum.map(&Map.get(&1, "store"))
    |> Enum.reject(fn store -> store == nil end)
    |> Enum.uniq

    # Compute additions
    additions = new_names
    |> Enum.reject(fn name ->
      existing_variables
      |> Enum.any?(fn var -> var.name == name end)
    end)

    # Compute deletions
    deletions = existing_variables
    |> Enum.reject(fn var ->
      new_names
      |> Enum.any?(fn name -> name == var.name end)
    end)

    # Insert additions
    additions |> Enum.each(fn name ->
      var = %QuestionnaireVariable{
        project_id: questionnaire.project_id,
        questionnaire_id: questionnaire.id,
        name: name,
      }
      var |> Repo.insert!
    end)

    # Delete deletions
    deletions |> Enum.each(fn var ->
      var
      |> Repo.delete!
    end)

    questionnaire
  end

  def sms_split_separator, do: "\u{1E}"

  def variables(questionnaire = %Questionnaire{}) do
    variables(all_steps(questionnaire))
  end

  def variables(steps) when is_list(steps) do
    steps
    |> Enum.map(&variables/1)
    |> Enum.reject(fn x -> x == nil end)
    |> Enum.uniq
  end

  def variables(%{"store" => var}) do
    var
  end

  def variables(_) do
    nil
  end

  def all_steps(%Questionnaire{steps: steps, quota_completed_steps: nil}) do
    get_steps(steps)
  end

  def all_steps(%Questionnaire{steps: steps, quota_completed_steps: quota_completed_steps}) do
    get_steps(steps) ++ quota_completed_steps
  end

  defp get_steps(steps) do
    result = steps |> Enum.flat_map(fn (item) ->
      case item["type"] do
        "section" ->
          item["steps"]
        _ -> [item]
      end
    end)
    result
  end

  def update_activity_logs(multi, conn, project, changeset) do
    questionnaire = changeset.data
    questionnaire_name = get_field(changeset, :name)

    multi =
      if Map.has_key?(changeset.changes, :name) do
        Multi.insert(multi, :rename_log, ActivityLog.rename_questionnaire(project, conn, questionnaire, questionnaire.name, changeset.changes.name))
      else
        multi
      end


    multi =
      if Map.has_key?(changeset.changes, :settings) && (changeset.changes.settings != questionnaire.settings) do
        Multi.insert(multi, :edit_settings_log, ActivityLog.edit_settings(project, conn, questionnaire))
      else
        multi
      end

    multi =
      if Map.has_key?(changeset.changes, :modes) do
        added = changeset.changes.modes -- questionnaire.modes
        removed = questionnaire.modes -- changeset.changes.modes
        multi = added |> Enum.reduce(multi, fn mode, multi ->
          Multi.insert(multi, {:add_mode_log, mode}, ActivityLog.add_questionnaire_mode(project, conn, questionnaire, questionnaire_name, mode))
        end)

        multi = removed |> Enum.reduce(multi, fn mode, multi ->
          Multi.insert(multi, {:remove_mode_log, mode}, ActivityLog.remove_questionnaire_mode(project, conn, questionnaire, questionnaire_name, mode))
        end)

        multi
      else
        multi
      end

    multi =
      if Map.has_key?(changeset.changes, :languages) do
        added = changeset.changes.languages -- questionnaire.languages
        removed = questionnaire.languages -- changeset.changes.languages
        multi = added |> Enum.reduce(multi, fn language, multi ->
          Multi.insert(multi, {:add_language_log, language}, ActivityLog.add_questionnaire_language(project, conn, questionnaire, questionnaire_name, language))
        end)

        multi = removed |> Enum.reduce(multi, fn language, multi ->
          Multi.insert(multi, {:remove_language_log, language}, ActivityLog.remove_questionnaire_language(project, conn, questionnaire, questionnaire_name, language))
        end)

        multi
      else
        multi
      end

    multi =
      if Map.has_key?(changeset.changes, :steps) do
        multi
          |> delta_steps(conn, project, changeset)
      else
        multi
      end

    multi =
      if Map.has_key?(changeset.changes, :quota_completed_steps) do
        multi
          |> delta_quota_completed_steps(conn, project, changeset)
      else
        multi
      end

    multi
  end

  defp delta_quota_completed_steps(multi, conn, project, changeset) do
    new_steps = if get_change(changeset, :quota_completed_steps), do: get_change(changeset, :quota_completed_steps) |> Map.new(&{&1["id"], &1}), else: %{}
    old_steps = if changeset.data.quota_completed_steps, do: changeset.data.quota_completed_steps |> Map.new(&{&1["id"], &1}), else: %{}

    delta(multi, conn, project, changeset.data, new_steps, old_steps)
  end

  defp delta_steps(multi, conn, project, changeset) do
    new_steps = get_change(changeset, :steps) |> Map.new(&{&1["id"], &1})
    old_steps = changeset.data.steps |> Map.new(&{&1["id"], &1})

    delta(multi, conn, project, changeset.data, new_steps, old_steps)
  end

  defp delta(multi, conn, project, questionnaire, new_steps, old_steps) do
    questionnaire_name = questionnaire.name

    new_step_ids = new_steps |> Map.keys()
    old_step_ids = old_steps |> Map.keys()

    # Create steps
    created_step_ids = new_step_ids -- old_step_ids

    multi = created_step_ids |> Enum.reduce(multi, fn step_id, multi ->
      step = new_steps[step_id]

      if  step["type"] == "section" do
        Multi.insert(multi, {:add_section_log, step_id}, ActivityLog.create_questionnaire_section(project, conn, questionnaire, questionnaire_name, step_id, step["title"]))
      else
        Multi.insert(multi, {:add_step_log, step_id}, ActivityLog.create_questionnaire_step(project, conn, questionnaire, questionnaire_name, step_id, step["title"], step["type"]))
      end
    end)

    # Delete steps
    deleted_step_ids = old_step_ids -- new_step_ids

    multi = deleted_step_ids |> Enum.reduce(multi, fn step_id, multi ->
      step = old_steps[step_id]

      if step["type"] == "section" do
        Multi.insert(multi, {:delete_section_log, step_id}, ActivityLog.delete_questionnaire_section(project, conn, questionnaire, questionnaire_name, step_id, step["title"]))
      else
        Multi.insert(multi, {:delete_step_log, step_id}, ActivityLog.delete_questionnaire_step(project, conn, questionnaire, questionnaire_name, step_id, step["title"], step["type"]))
      end
    end)

    # Rename steps
    common_step_ids = new_step_ids -- (new_step_ids -- old_step_ids)

    multi = common_step_ids |> Enum.reduce(multi, fn step_id, multi ->
      new_step = new_steps[step_id]
      old_step = old_steps[step_id]


      multi = if new_step["title"] != old_step["title"] do
        if new_step["type"] == "section" do
          Multi.insert(multi, {:rename_section_log, step_id}, ActivityLog.rename_questionnaire_section(project, conn, questionnaire, questionnaire_name, step_id, old_step["title"], new_step["title"]))
        else
          Multi.insert(multi, {:rename_step_log, step_id}, ActivityLog.rename_questionnaire_step(project, conn, questionnaire, questionnaire_name, step_id, old_step["title"], new_step["title"]))
        end
      else
        multi
      end

      if Map.delete(new_step, "title") != Map.delete(old_step, "title") do
        if new_step["type"] == "section" && !is_nil(new_step["steps"]) do
          current_new_steps = new_step["steps"] |> Map.new(&{&1["id"], &1})
          current_old_steps = old_step["steps"] |> Map.new(&{&1["id"], &1})

          delta(multi, conn, project, questionnaire, current_new_steps, current_old_steps)
        else
          Multi.insert(multi, {:edit_step_log, step_id}, ActivityLog.edit_questionnaire_step(project, conn, questionnaire, questionnaire_name, step_id, new_step["title"]))
        end
      else
        multi
      end
    end)

    multi
  end

  def ignored_values_from_relevant_steps(questionnaire) do
    not_empty = fn str -> str != "" end
    (questionnaire.partial_relevant_config["ignored_values"] || "")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(not_empty)
    |> Enum.map(&String.upcase/1)
  end

  def partial_relevant_enabled?(partial_relevant_config),
    do:
      !!partial_relevant_config["enabled"]
end
