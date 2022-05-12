defmodule Ask.Repo.Migrations.AddExitMessageAndExitCodeToSurveys do
  use Ecto.Migration
  import Ecto.Query

  def up do
    alter table(:surveys) do
      add :exit_code, :integer
      add :exit_message, :string
    end

    flush()

    from(s in "surveys", where: s.state == "completed")
    |> Ask.Repo.update_all(
      set: [state: :terminated, exit_code: 0, exit_message: "Successfully completed"]
    )

    from(s in "surveys", where: s.state == "cancelled")
    |> Ask.Repo.update_all(
      set: [state: :terminated, exit_code: 1, exit_message: "Cancelled by user"]
    )
  end

  def down do
    from(s in "surveys", where: s.exit_code == 0)
    |> Ask.Repo.update_all(set: [state: "completed"])

    from(s in "surveys", where: s.exit_code == 1)
    |> Ask.Repo.update_all(set: [state: "cancelled"])

    alter table(:surveys) do
      remove :exit_code
      remove :exit_message
    end
  end
end
