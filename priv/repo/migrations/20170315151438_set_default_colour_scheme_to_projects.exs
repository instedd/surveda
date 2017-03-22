defmodule Ask.Repo.Migrations.SetDefaultColourSchemeToProjects do
  use Ecto.Migration

  def change do
    Ask.Repo.query!(~s(update projects set colour_scheme = 'default'))
  end
end
