defmodule Ask.Repo.Migrations.AddDefaultDispositionToRejectedRespondents do
  use Ecto.Migration
  alias Ask.Repo

  def up do
    Repo.transaction(fn ->
      Repo.query!(
        """
        UPDATE respondents
        SET disposition = 'rejected'
        WHERE state = 'rejected'
        AND disposition IS NULL
        """,
        []
      )
    end)
  end

  def down do
  end
end
