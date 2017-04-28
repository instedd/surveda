defmodule Ask.Repo.Migrations.AddLanguageToRespondents do
  use Ecto.Migration

  def change do
    alter table(:respondents) do
      add :language, :string
    end
  end
end
