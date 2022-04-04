defmodule Ask.Repo.Migrations.CreateTranslation do
  use Ecto.Migration

  def change do
    create table(:translations) do
      add :mode, :string
      add :source_lang, :string
      add :source_text, :string
      add :target_lang, :string
      add :target_text, :string
      add :project_id, references(:projects, on_delete: :nothing)
      add :questionnaire_id, references(:questionnaires, on_delete: :nothing)

      timestamps()
    end

    create index(:translations, [:project_id])
    create index(:translations, [:questionnaire_id])
  end
end
