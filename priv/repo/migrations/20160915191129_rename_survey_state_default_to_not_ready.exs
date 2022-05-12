defmodule Ask.Repo.Migrations.RenameSurveyStateDefaultToNotReady do
  use Ecto.Migration
  import Ecto.Query

  def up do
    from(s in Ask.Survey, where: s.state == :pending)
    |> Ask.Repo.update_all(set: [state: :not_ready])
  end

  def down do
    from(s in Ask.Survey, where: s.state == :not_ready)
    |> Ask.Repo.update_all(set: [state: :pending])
  end
end
