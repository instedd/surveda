defmodule Ask.TestHelpers do
  defmacro __using__(_) do
    quote do
      def create_project_for_user(user, options \\ []) do
        level = options[:level] || "owner"
        archived = options[:archived] || false
        updated_at = options[:updated_at] || Timex.now
        project = insert(:project, archived: archived, updated_at: updated_at)
        insert(:project_membership, user: user, project: project, level: level)
        project
      end
    end
  end
end
