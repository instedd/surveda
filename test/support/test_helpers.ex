defmodule Ask.TestHelpers do
  defmacro __using__(_) do
    quote do
      def create_project_for_user(user) do
        project = insert(:project)
        insert(:project_membership, user: user, project: project, level: "owner")
        project
      end
    end
  end
end
