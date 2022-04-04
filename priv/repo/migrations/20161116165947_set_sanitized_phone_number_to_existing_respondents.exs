defmodule Ask.Repo.Migrations.SetSanitizedPhoneNumberToExistingRespondents do
  use Ecto.Migration

  def change do
    result = Ask.Repo.query!("select id, phone_number from respondents")

    result.rows
    |> Enum.each(fn [id, phone_number] ->
      sanitized_phone_number =
        Ask.Repo.Migrations.SetSanitizedPhoneNumberToExistingRespondents.sanitize_phone_number(
          phone_number
        )

      Ask.Repo.query!("update respondents set sanitized_phone_number = ? where id = ?", [
        sanitized_phone_number,
        id
      ])
    end)
  end

  def sanitize_phone_number(text) do
    ~r/[^\+\d]/ |> Regex.replace(text, "")
  end
end
