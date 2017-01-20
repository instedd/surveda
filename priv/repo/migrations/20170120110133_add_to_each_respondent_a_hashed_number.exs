defmodule Ask.Repo.Migrations.AddToEachRespondentAHashedNumber do
  use Ecto.Migration

  alias Ask.Repo

  defmodule Respondent do
    use Ask.Web, :model

    def hash_phone_number(phone_number, salt) do
      String.slice(:crypto.hash(:md5, salt <> phone_number) |> Base.encode16(case: :lower), -12, 12)
    end

  end

  def up do
    Repo.query!("SELECT r.id, r.phone_number, r.hashed_number, p.salt
      FROM respondents AS r
      INNER JOIN surveys AS s ON s.id = r.survey_id
      INNER JOIN projects AS p ON p.id = s.project_id").rows |> Enum.each(fn [respondent_id, phone_number, hashed_number, salt] ->
      if !hashed_number do
        Repo.query!("update respondents set hashed_number = '#{Respondent.hash_phone_number(phone_number, salt)}' where id = #{respondent_id}")
      end
    end)
  end

  def down do
    Repo.query!("update respondents set hashed_number = NULL")
  end
end
