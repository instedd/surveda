defmodule Ask.Repo.Migrations.FixRespondentStatsTrigger do
  use Ecto.Migration

  def up do
    Repo.transaction(fn ->
      Repo.query!(
        """
        DROP TRIGGER respondents_upd;
        """
      )

      Repo.query!(
        Repo.query!(
          """
          CREATE TRIGGER respondents_upd
          AFTER UPDATE ON respondents
          FOR EACH ROW
          BEGIN
    
            # This is a hack for using the `select for update`
            # so we can lock all the records that will get updated 
            # by this trigger before actually modifying them
            # so we prevent this trigger to generate deadlocks
            # see #1744
            DECLARE temp_stats INT;
    
            SELECT count(*) 
            INTO temp_stats
            FROM respondent_stats
            WHERE (survey_id = OLD.survey_id
                      AND questionnaire_id = IFNULL(OLD.questionnaire_id, 0)
                      AND state = OLD.state
                      AND disposition = OLD.disposition
                      AND quota_bucket_id = IFNULL(OLD.quota_bucket_id, 0)
                      AND mode = IFNULL(OLD.mode, ''))
            OR (survey_id = NEW.survey_id
                      AND questionnaire_id = IFNULL(NEW.questionnaire_id, 0)
                      AND state = NEW.state
                      AND disposition = NEW.disposition
                      AND quota_bucket_id = IFNULL(NEW.quota_bucket_id, 0)
                      AND mode = IFNULL(NEW.mode, ''))
            FOR UPDATE;
    
            UPDATE respondent_stats
               SET `count` = `count` - 1
             WHERE survey_id = OLD.survey_id
               AND questionnaire_id = IFNULL(OLD.questionnaire_id, 0)
               AND state = OLD.state
               AND disposition = OLD.disposition
               AND quota_bucket_id = IFNULL(OLD.quota_bucket_id, 0)
               AND mode = IFNULL(OLD.mode, '')
            ;

            INSERT INTO respondent_stats(survey_id, questionnaire_id, state, disposition, quota_bucket_id, mode, `count`)
            VALUES (NEW.survey_id, IFNULL(NEW.questionnaire_id, 0), NEW.state, NEW.disposition, IFNULL(NEW.quota_bucket_id, 0), IFNULL(NEW.mode, ''), 1)
            ON DUPLICATE KEY UPDATE `count` = `count` + 1
            ;
    
          END;
          """
        )
      )
    end)
  end

  def down do
    # Re-create the trigger as it was before
    Repo.transaction(fn ->
      Repo.query!(
        """
        DROP TRIGGER respondents_upd;
        """
      )

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
           AND quota_bucket_id = IFNULL(OLD.quota_bucket_id, 0)
           AND mode = IFNULL(OLD.mode, '')
        ;

        INSERT INTO respondent_stats(survey_id, questionnaire_id, state, disposition, quota_bucket_id, mode, `count`)
        VALUES (NEW.survey_id, IFNULL(NEW.questionnaire_id, 0), NEW.state, NEW.disposition, IFNULL(NEW.quota_bucket_id, 0), IFNULL(NEW.mode, ''), 1)
        ON DUPLICATE KEY UPDATE `count` = `count` + 1
        ;

      END;
      """)
    end)
  end
end
