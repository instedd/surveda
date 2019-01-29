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

      def setup_surveys_with_channels(surveys, channels) do
        respondent_groups =
          Enum.zip(surveys, channels)
          |> Enum.map(fn {s, c} ->
            insert(
              :respondent_group,
              survey: s,
              respondent_group_channels:
                [
                  insert(
                    :respondent_group_channel,
                    channel: c
                  )
                ]
            )
          end)

        respondent_groups
      end
    end
  end
end
