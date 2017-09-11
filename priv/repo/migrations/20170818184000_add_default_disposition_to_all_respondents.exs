defmodule Ask.Repo.Migrations.AddDefaultDispositionToAllRespondents do
  use Ecto.Migration
  alias Ask.Repo

  def change do
    Repo.transaction(fn ->
      Repo.query!("""
        UPDATE respondents
        SET disposition = 'contacted'
        WHERE state = 'cancelled'
        """, [])

      Repo.query!("""
        UPDATE respondents
        SET disposition = 'failed'
        WHERE state = 'failed'
        """, [])

      Repo.query!("""
        UPDATE respondents
        SET disposition = 'registered'
        WHERE state = 'pending'
        """, [])
    end)
  end

end
