defmodule Ask.Repo.Migrations.AddDefaultDispositionToAllRespondents do
  use Ecto.Migration
  alias Ask.Repo

  def up do
    Repo.transaction(fn ->
      Repo.query!(
        """
        UPDATE respondents
        SET disposition = 'contacted'
        WHERE state = 'cancelled'
        AND disposition IS NULL
        """,
        []
      )

      Repo.query!(
        """
        UPDATE respondents
        SET disposition = 'failed'
        WHERE state = 'failed'
        AND disposition IS NULL
        """,
        []
      )

      Repo.query!(
        """
        UPDATE respondents
        SET disposition = 'registered'
        WHERE state = 'pending'
        AND disposition IS NULL
        """,
        []
      )
    end)
  end

  def down do
  end
end
