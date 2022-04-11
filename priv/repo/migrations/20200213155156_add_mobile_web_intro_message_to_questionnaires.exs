defmodule Ask.Repo.Migrations.AddMobileWebIntroMessageToQuestionnaires do
  use Ecto.Migration
  alias Ask.Ecto.Type.JSON
  alias Ask.Repo

  defmodule Questionnaire do
    use AskWeb, :model

    schema "questionnaires" do
      field(:name, :string)
      field(:description, :string)
      field(:modes, Ask.Ecto.Type.StringList)
      field(:steps, JSON)
      field(:quota_completed_steps, JSON)
      field(:settings, JSON)
      field(:languages, JSON)
      field(:default_language, :string)
      field(:valid, :boolean)
      field(:deleted, :boolean)
      belongs_to(:snapshot_of_questionnaire, Ask.Questionnaire, foreign_key: :snapshot_of)
      belongs_to(:project, Ask.Project)
      has_many(:questionnaire_variables, Ask.QuestionnaireVariable, on_delete: :delete_all)
      has_many(:translations, Ask.Translation, on_delete: :delete_all)
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [
        :project_id,
        :name,
        :description,
        :modes,
        :steps,
        :quota_completed_steps,
        :languages,
        :default_language,
        :valid,
        :settings,
        :snapshot_of,
        :deleted
      ])
      |> validate_required([:project_id, :modes, :steps, :settings])
      |> foreign_key_constraint(:project_id)
      |> foreign_key_constraint(:snapshot_of)
    end
  end

  defp mobile_web_intro_message(%{"title" => title} = _settings, default_language),
    do: Map.get(title, default_language)

  defp mobile_web_intro_message(_settings, _default_language), do: nil

  def up do
    for q <- Repo.all(Questionnaire) do
      mobile_web_intro_message = mobile_web_intro_message(q.settings, q.default_language)

      if mobile_web_intro_message do
        settings = Map.put(q.settings, "mobile_web_intro_message", mobile_web_intro_message)
        Questionnaire.changeset(q, %{"settings" => settings}) |> Repo.update!()
      end
    end
  end

  def down do
    for q <- Repo.all(Questionnaire) do
      if Map.has_key?(q.settings, "mobile_web_intro_message") do
        settings = Map.delete(q.settings, "mobile_web_intro_message")
        Questionnaire.changeset(q, %{"settings" => settings}) |> Repo.update!()
      end
    end
  end
end
