defmodule Ask.Repo.Migrations.SynchronizeCompletedRespondents do
  use Ecto.Migration
  alias Ask.Repo

  def up do
    Repo.transaction(fn ->
      Repo.query!(
        """
        INSERT INTO completed_respondents(survey_id, questionnaire_id, quota_bucket_id, mode, date, count)
        SELECT survey_id, IFNULL(questionnaire_id, 0), IFNULL(quota_bucket_id, 0), IFNULL(mode, ''), DATE(updated_at), count(*)
        FROM respondents
        WHERE disposition = 'completed'
        GROUP BY survey_id, questionnaire_id, quota_bucket_id, mode, DATE(updated_at)
        """,
        []
      )

      Repo.query!("""
      CREATE TRIGGER on_respondents_completed_ins
      AFTER INSERT ON respondents
      FOR EACH ROW
      BEGIN

        IF NEW.disposition = 'completed' THEN
          INSERT INTO completed_respondents(survey_id, questionnaire_id, quota_bucket_id, mode, date, count)
          VALUES (NEW.survey_id, IFNULL(NEW.questionnaire_id, 0), IFNULL(NEW.quota_bucket_id, 0), IFNULL(NEW.mode, ''), DATE(NEW.updated_at), 1)
          ON DUPLICATE KEY UPDATE `count` = `count` + 1;
        END IF;

      END;
      """)

      Repo.query!("""
      CREATE TRIGGER on_respondents_completed_upd
      AFTER UPDATE ON respondents
      FOR EACH ROW
      BEGIN

        IF NEW.disposition = 'completed' AND OLD.disposition <> 'completed' THEN
          INSERT INTO completed_respondents(survey_id, questionnaire_id, quota_bucket_id, mode, date, count)
          VALUES (NEW.survey_id, IFNULL(NEW.questionnaire_id, 0), IFNULL(NEW.quota_bucket_id, 0), IFNULL(NEW.mode, ''), DATE(NEW.updated_at), 1)
          ON DUPLICATE KEY UPDATE `count` = `count` + 1;
        ELSEIF NEW.disposition <> 'completed' AND OLD.disposition = 'completed' THEN
          UPDATE completed_respondents
             SET `count` = `count` - 1
           WHERE survey_id = OLD.survey_id
             AND questionnaire_id = IFNULL(OLD.questionnaire_id, 0)
             AND quota_bucket_id = IFNULL(OLD.quota_bucket_id, 0)
             AND mode = IFNULL(OLD.mode, '')
             AND date = DATE(OLD.updated_at);
        END IF;

      END;
      """)

      Repo.query!("""
      CREATE TRIGGER on_respondents_completed_del
      AFTER DELETE ON respondents
      FOR EACH ROW
      BEGIN

        IF OLD.disposition = 'completed' THEN
          UPDATE completed_respondents
             SET `count` = `count` - 1
           WHERE survey_id = OLD.survey_id
             AND questionnaire_id = IFNULL(OLD.questionnaire_id, 0)
             AND quota_bucket_id = IFNULL(OLD.quota_bucket_id, 0)
             AND mode = IFNULL(OLD.mode, '')
             AND date = DATE(OLD.updated_at);
        END IF;

      END;
      """)
    end)
  end

  def down do
    Repo.query!("DROP TRIGGER on_respondents_completed_ins")
    Repo.query!("DROP TRIGGER on_respondents_completed_upd")
    Repo.query!("DROP TRIGGER on_respondents_completed_del")
    Repo.query!("DELETE FROM completed_respondents")
  end
end
