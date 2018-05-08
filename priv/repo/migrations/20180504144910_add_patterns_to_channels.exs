defmodule Ask.Repo.Migrations.AddPatternsToChannels do
  use Ecto.Migration
  import Ecto.Query
  alias Ask.Repo

  defmodule Channel do
    use Ask.Web, :model

    schema "channels" do
      field :patterns, Ask.Ecto.Type.JSON
    end
  end

  def up do
    alter table(:channels) do
      add :patterns, :text
    end

    flush()

    from(c in Channel) |> Repo.update_all(set: [patterns: []])
  end

  def down do
    alter table(:channels) do
      remove :patterns
    end
  end
end
