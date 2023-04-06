defmodule Ask.Repo.Migrations.RemoveProjectMembershipsDuplicates do
  use Ecto.Migration

  def up do
    # Remove duplicates and keep max level in column level for each user and project in project_membnerships
    execute("""
      DELETE t1
      FROM project_memberships t1
      INNER JOIN (
          SELECT user_id, project_id, MAX(
              CASE level 
                  WHEN 'owner' THEN 4 
                  WHEN 'admin' THEN 3 
                  WHEN 'editor' THEN 2 
                  WHEN 'reader' THEN 1 
                  ELSE 0 
              END) AS max_level
          FROM project_memberships
          GROUP BY user_id, project_id
      ) t2 
      ON t1.user_id = t2.user_id 
      AND t1.project_id = t2.project_id 
      AND CASE t1.level 
              WHEN 'owner' THEN 4 
              WHEN 'admin' THEN 3 
              WHEN 'editor' THEN 2 
              WHEN 'reader' THEN 1 
              ELSE 0 
          END < t2.max_level;
    """)
  end
end
