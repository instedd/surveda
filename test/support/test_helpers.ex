defmodule Ask.TestHelpers do
  defmacro __using__(_) do
    quote do
      use Ask.DummySteps
      alias Ask.Runtime.{Broker, Flow}
      alias Ask.{PanelSurvey, Repo, Respondent, Survey}

      @foo_string "foo"
      @bar_string "bar"

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

      defp create_running_survey_with_channel_and_respondent_with_options(options \\ []) do
        steps = Keyword.get(options, :steps, @dummy_steps)
        mode = Keyword.get(options, :mode, "sms")
        schedule = Keyword.get(options, :schedule, Ask.Schedule.always())
        fallback_delay = Keyword.get(options, :fallback_delay, "10m")
        user = Keyword.get(options, :user, nil)
        simulation = Keyword.get(options, :simulation, false)

        project = if (user), do: create_project_for_user(user), else: nil
        test_channel = Ask.TestChannel.new(false, mode == "sms")

        channel_type = case mode do
          "mobileweb" -> "sms"
          _ -> mode
        end

        channel = insert(:channel, settings: test_channel |> Ask.TestChannel.settings, type: channel_type)
        quiz = insert(:questionnaire, steps: steps, quota_completed_steps: nil)
        survey = %{schedule: schedule, state: "running", questionnaires: [quiz], mode: [[mode]], fallback_delay: fallback_delay, simulation: simulation}
        survey = if (project), do: Map.put(survey, :project, project), else: survey
        survey = insert(:survey, survey)
        group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Ask.Repo.preload(:channels)

        Ask.RespondentGroupChannel.changeset(%Ask.RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: mode}) |> Ask.Repo.insert

        respondent = insert(:respondent, survey: survey, respondent_group: group)
        phone_number = respondent.canonical_phone_number

        [survey, group, test_channel, respondent, phone_number]
      end

      defp create_running_survey_with_channel_and_respondent(steps \\ @dummy_steps, mode \\ "sms", schedule \\ Ask.Schedule.always(), fallback_delay \\ "10m") do
        create_running_survey_with_channel_and_respondent_with_options(
          steps: steps,
          mode: mode,
          schedule: schedule,
          fallback_delay: fallback_delay
        )
      end

      def create_several_respondents(survey, group, n) when n <= 1 do
        [insert(:respondent, survey: survey, respondent_group: group)]
      end

      def create_several_respondents(survey, group, n) do
        [create_several_respondents(survey, group, n - 1) | insert(:respondent, survey: survey, respondent_group: group)]
      end

      def assert_respondents_by_state(survey, active, pending) do
        [a, p] = get_respondents_by_state(survey)

        assert a == active
        assert p == pending
      end

      defp broker_poll(), do: Broker.handle_info(:poll, nil)

      defp respondent_reply(respondent_id, reply_message, mode) do
        respondent = Repo.get!(Respondent, respondent_id)
        Ask.Runtime.Survey.sync_step(respondent, Flow.Message.reply(reply_message), mode)
      end

      defp get_respondents_by_state(survey) do
        by_state = Ask.Repo.all(
                     from r in assoc(survey, :respondents),
                     group_by: :state,
                     select: {r.state, count("*")}) |> Enum.into(%{})
        [by_state["active"] || 0, by_state["pending"] || 0]
      end

      # Format a timestamp without microseconds the same way the controller does.
      defp to_iso8601(timestamp) do
        Timex.to_datetime(timestamp) |> DateTime.to_iso8601()
      end

      defp dummy_panel_survey(project \\ nil) do
        project = if project, do: project, else: insert(:project)
        {:ok, panel_survey} = PanelSurvey.create_panel_survey(%{name: @foo_string, project_id: project.id})
        panel_survey
      end

      defp dummy_panel_survey_inside_folder(project \\ nil) do
        project = if project, do: project, else: insert(:project)
        folder = insert(:folder)
        {:ok, panel_survey} = PanelSurvey.create_panel_survey(%{name: @foo_string, project_id: project.id, folder_id: folder.id})
        panel_survey
      end

      defp panel_survey_with_occurrence() do
        panel_survey = insert(:panel_survey)
        insert(:survey, panel_survey:  panel_survey, project: panel_survey.project)
        # Reload the panel survey. One of its surveys has changed, so it's outdated
        Repo.get!(Ask.PanelSurvey, panel_survey.id)
      end

      defp terminate_survey(survey) do
        Survey.changeset(survey, %{state: "terminated"})
        |> Repo.update!()
      end

      defp complete_last_occurrence_of_panel_survey(panel_survey) do
        Ask.PanelSurvey.latest_occurrence(panel_survey)
        |> terminate_survey()

        # Reload the panel survey. One of its surveys has changed, so it's outdated
        Repo.get!(Ask.PanelSurvey, panel_survey.id)
      end

      defp panel_survey_with_last_occurrence_terminated() do
        panel_survey_with_occurrence()
        |> complete_last_occurrence_of_panel_survey()
      end
    end
  end
end
