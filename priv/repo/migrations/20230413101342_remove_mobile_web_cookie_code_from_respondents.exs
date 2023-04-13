defmodule Ask.Repo.Migrations.RemoveMobileWebCookieCodeFromRespondents do
  use Ecto.Migration

  def up do
    alter table(:respondents) do
      remove :mobile_web_cookie_code
    end
  end

  def down do
    alter table(:respondents) do
      add :mobile_web_cookie_code, :string
    end
  end
end
