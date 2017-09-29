defmodule Ask.Repo.Migrations.SetDefaultStateForSurveys do
  use Ecto.Migration
  import Ecto.Query

  def up do
    alter table(:surveys) do
      modify :state, :string, default: "pending"
    end
    flush()

    from(s in Ask.Survey, where: is_nil(s.state))
    |> Ask.Repo.update_all(set: [state: "pending"])
  end

  def down do
    alter table(:surveys) do
      modify :state, :string
    end
  end
end
