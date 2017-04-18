defmodule Ask.Repo.Migrations.AddMobileWebCookieCodeToRespondents do
  use Ecto.Migration

  def change do
    alter table(:respondents) do
      add :mobile_web_cookie_code, :string
    end
  end
end
