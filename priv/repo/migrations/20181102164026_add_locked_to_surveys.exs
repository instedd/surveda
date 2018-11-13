defmodule Ask.Repo.Migrations.AddLockedToSurveys do
  use Ecto.Migration
  import Ecto.Query
  alias Ask.Repo

  defmodule Survey do
    use Ask.Web, :model

    schema "surveys" do
      field :locked, :boolean
    end
  end

  def up do
    alter table(:surveys) do
      add :locked, :boolean, default: false
    end

    flush()

    from(s in Survey) |> Repo.update_all(set: [locked: false])
  end

  def down do
    alter table(:surveys) do
      remove :locked
    end
  end
end
