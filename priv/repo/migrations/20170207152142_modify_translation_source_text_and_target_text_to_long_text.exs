defmodule Ask.Repo.Migrations.ModifyTranslationSourceTextAndTargetTextToLongText do
  use Ecto.Migration

  def up do
    alter table(:translations) do
      modify :source_text, :longtext
      modify :target_text, :longtext
    end
  end

  def down do
    alter table(:translations) do
      modify :source_text, :string
      modify :target_text, :string
    end
  end
end
