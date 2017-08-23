defmodule Ask.Repo.Migrations.SynchronizeRespondentStats do
  use Ecto.Migration
  alias Ask.Repo

  def up do
    Repo.transaction(fn ->
      Repo.query!("""
        INSERT INTO respondent_stats
        SELECT survey_id, IFNULL(questionnaire_id, 0), state, disposition, count(*)
        FROM respondents
        GROUP BY survey_id, questionnaire_id, state, disposition
        """, [])

      Repo.query!("""
        CREATE TRIGGER respondents_ins
        AFTER INSERT ON respondents
        FOR EACH ROW
        BEGIN

          INSERT INTO respondent_stats(survey_id, questionnaire_id, state, disposition, `count`)
          VALUES (NEW.survey_id, IFNULL(NEW.questionnaire_id, 0), NEW.state, NEW.disposition, 1)
          ON DUPLICATE KEY UPDATE `count` = `count` + 1
          ;

        END;
        """)

      Repo.query!("""
        CREATE TRIGGER respondents_del
        AFTER DELETE ON respondents
        FOR EACH ROW
        BEGIN

          UPDATE respondent_stats
             SET `count` = `count` - 1
           WHERE survey_id = OLD.survey_id
             AND questionnaire_id = IFNULL(OLD.questionnaire_id, 0)
             AND state = OLD.state
             AND disposition = OLD.disposition
          ;

        END;
        """)

      Repo.query!("""
        CREATE TRIGGER respondents_upd
        AFTER UPDATE ON respondents
        FOR EACH ROW
        BEGIN

          UPDATE respondent_stats
             SET `count` = `count` - 1
           WHERE survey_id = OLD.survey_id
             AND questionnaire_id = IFNULL(OLD.questionnaire_id, 0)
             AND state = OLD.state
             AND disposition = OLD.disposition
          ;

          INSERT INTO respondent_stats(survey_id, questionnaire_id, state, disposition, `count`)
          VALUES (NEW.survey_id, IFNULL(NEW.questionnaire_id, 0), NEW.state, NEW.disposition, 1)
          ON DUPLICATE KEY UPDATE `count` = `count` + 1
          ;

        END;
        """)

    end)
  end

  def down do
    Repo.query!("DROP TRIGGER respondents_ins")
    Repo.query!("DROP TRIGGER respondents_del")
    Repo.query!("DROP TRIGGER respondents_upd")
    Repo.query!("DELETE FROM respondent_stats")
  end
end
