defmodule Ask.Repo.Migrations.AddToEachRespondentAHashedNumber do
  use Ecto.Migration

  alias Ask.Repo

  defmodule Respondent do
    use Ask.Web, :model

    def hash_phone_number(phone_number, salt) do
      String.slice(
        :crypto.hash(:md5, salt <> phone_number) |> Base.encode16(case: :lower),
        -12,
        12
      )
    end
  end

  def up do
    Repo.query!("SELECT s.id, p.salt
      FROM surveys AS s
      INNER JOIN projects AS p ON s.project_id = p.id").rows
    |> Enum.each(fn [survey_id, salt] ->
      Repo.query!(
        "UPDATE respondents
          SET hashed_number = right(md5(concat(?, phone_number)), 12)
          WHERE survey_id = ?",
        [salt, survey_id]
      )
    end)
  end

  def down do
    Repo.query!("update respondents set hashed_number = NULL")
  end
end
