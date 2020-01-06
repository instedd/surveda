defmodule Ask.TestHelpers do
  defmacro __using__(_) do
    quote do
      use Ask.DummySteps

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

      defp create_running_survey_with_channel_and_respondent(steps \\ @dummy_steps, mode \\ "sms", schedule \\ Ask.Schedule.always(), fallback_delay \\ "10m") do
        test_channel = Ask.TestChannel.new(false, mode == "sms")

        channel_type = case mode do
          "mobileweb" -> "sms"
          _ -> mode
        end

        channel = insert(:channel, settings: test_channel |> Ask.TestChannel.settings, type: channel_type)
        quiz = insert(:questionnaire, steps: steps, quota_completed_steps: nil)
        survey = insert(:survey, %{schedule: schedule, state: "running", questionnaires: [quiz], mode: [[mode]], fallback_delay: fallback_delay})
        group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Ask.Repo.preload(:channels)

        Ask.RespondentGroupChannel.changeset(%Ask.RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: mode}) |> Ask.Repo.insert

        respondent = insert(:respondent, survey: survey, respondent_group: group)
        phone_number = respondent.sanitized_phone_number

        [survey, group, test_channel, respondent, phone_number]
      end

      defp mock_time(time) do
        Ask.TimeMock
        |> stub(:now, fn () -> time end)
        time
      end

    end
  end
end
