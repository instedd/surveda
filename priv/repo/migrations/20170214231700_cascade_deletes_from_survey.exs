defmodule Ask.Repo.Migrations.CascadeDeletesFromSurvey do
  use Ecto.Migration

  def up do
    alter_references(:delete_all)
  end

  def down do
    alter_references(:nothing)
  end

  defp alter_references(on_delete) do
    alter_reference(:respondent_groups, :surveys, :survey_id, on_delete)
    alter_reference(:respondents, :surveys, :survey_id, on_delete)

    alter_reference(
      :respondent_group_channels,
      :respondent_groups,
      :respondent_group_id,
      on_delete
    )

    alter_reference(:respondents, :respondent_groups, :respondent_group_id, on_delete)
    alter_reference(:responses, :respondents, :respondent_id, on_delete)
    alter_reference(:survey_questionnaires, :surveys, :survey_id, on_delete)
    alter_reference(:respondent_disposition_history, :respondents, :respondent_id, on_delete)
  end

  defp alter_reference(from_table, to_table, fk_column, on_delete) do
    Ask.Repo.query!("ALTER TABLE #{from_table} DROP FOREIGN KEY #{from_table}_#{fk_column}_fkey")

    alter table(from_table) do
      modify fk_column, references(to_table, on_delete: on_delete)
    end
  end
end
