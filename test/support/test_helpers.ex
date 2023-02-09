defmodule Ask.TestHelpers do
  defmacro __using__(_) do
    quote do
      use Ask.DummySteps
      alias Ask.Runtime.{Broker, Flow, RespondentGroupAction}
      alias Ask.{PanelSurvey, Repo, Respondent, Survey, TestChannel}

      @foo_string "foo"
      @bar_string "bar"
      @dummy_int 5

      def create_project_for_user(user, options \\ []) do
        level = options[:level] || "owner"
        archived = options[:archived] || false
        updated_at = options[:updated_at] || Timex.now()
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
              respondent_group_channels: [
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

        project = if user, do: create_project_for_user(user), else: nil
        test_channel = Ask.TestChannel.new(false, mode == "sms")

        channel_type =
          case mode do
            "mobileweb" -> "sms"
            _ -> mode
          end

        channel =
          insert(:channel,
            settings: test_channel |> Ask.TestChannel.settings(),
            type: channel_type
          )

        quiz = insert(:questionnaire, steps: steps, quota_completed_steps: nil)

        survey = %{
          schedule: schedule,
          state: :running,
          questionnaires: [quiz],
          mode: [[mode]],
          fallback_delay: fallback_delay,
          simulation: simulation
        }

        survey = if project, do: Map.put(survey, :project, project), else: survey
        survey = insert(:survey, survey)

        group =
          insert(:respondent_group, survey: survey, respondents_count: 1)
          |> Ask.Repo.preload(:channels)

        Ask.RespondentGroupChannel.changeset(%Ask.RespondentGroupChannel{}, %{
          respondent_group_id: group.id,
          channel_id: channel.id,
          mode: mode
        })
        |> Ask.Repo.insert()

        respondent = insert(:respondent, survey: survey, respondent_group: group)
        phone_number = respondent.canonical_phone_number

        [survey, group, test_channel, respondent, phone_number]
      end

      defp create_running_survey_with_channel_and_respondent(
             steps \\ @dummy_steps,
             mode \\ "sms",
             schedule \\ Ask.Schedule.always(),
             fallback_delay \\ "10m"
           ) do
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
        [
          create_several_respondents(survey, group, n - 1)
          | insert(:respondent, survey: survey, respondent_group: group)
        ]
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
        by_state =
          Ask.Repo.all(
            from r in assoc(survey, :respondents),
              group_by: :state,
              select: {r.state, count("*")}
          )
          |> Enum.into(%{})

        [by_state[:active] || 0, by_state[:pending] || 0]
      end

      # Format a timestamp without microseconds the same way the controller does.
      defp to_iso8601(timestamp) do
        Timex.to_datetime(timestamp) |> DateTime.to_iso8601()
      end

      defp panel_survey_generator_survey(project \\ nil) do
        project = if project, do: project, else: insert(:project)
        insert(:survey, state: :ready, project: project, generates_panel_survey: true)
      end

      defp panel_survey_generator_survey_with_cutoff_and_comparisons() do
        survey = panel_survey_generator_survey()

        dummy_cutoff_and_comparisons = %{
          comparisons: @foo_string,
          quota_vars: @bar_string,
          cutoff: @dummy_int,
          count_partial_results: true
        }

        survey =
          Survey.changeset(survey, dummy_cutoff_and_comparisons)
          |> Repo.update!()
      end

      defp panel_survey_generator_survey_in_folder(project \\ nil) do
        panel_survey_generator_survey(project)
        |> include_in_folder()
      end

      defp include_in_folder(survey) do
        project = Repo.preload(survey, :project).project
        folder = insert(:folder, project: project)

        Survey.changeset(survey, %{folder_id: folder.id})
        |> Repo.update!()
      end

      defp dummy_panel_survey(project \\ nil) do
        project = if project, do: project, else: insert(:project)
        survey = panel_survey_generator_survey(project)
        {:ok, panel_survey} = Ask.Runtime.PanelSurvey.create_panel_survey_from_survey(survey)
        panel_survey
      end

      defp dummy_panel_survey_in_folder(project \\ nil) do
        project = if project, do: project, else: insert(:project)
        survey = panel_survey_generator_survey_in_folder(project)
        {:ok, panel_survey} = Ask.Runtime.PanelSurvey.create_panel_survey_from_survey(survey)
        panel_survey
      end

      defp panel_survey_with_wave() do
        panel_survey = insert(:panel_survey)
        insert(:survey, panel_survey: panel_survey, project: panel_survey.project)
        # Reload the panel survey. One of its surveys has changed, so it's outdated
        Repo.get!(Ask.PanelSurvey, panel_survey.id)
      end

      defp terminate_survey(survey) do
        Survey.changeset(survey, %{state: "terminated"})
        |> Repo.update!()
      end

      defp complete_last_wave_of_panel_survey(panel_survey) do
        Ask.PanelSurvey.latest_wave(panel_survey)
        |> terminate_survey()

        # Reload the panel survey. One of its surveys has changed, so it's outdated
        Repo.get!(Ask.PanelSurvey, panel_survey.id)
      end

      defp panel_survey_with_last_wave_terminated() do
        panel_survey_with_wave()
        |> complete_last_wave_of_panel_survey()
      end

      defp completed_panel_survey_with_respondents() do
        panel_survey = panel_survey_with_wave()
        latest_wave = Ask.PanelSurvey.latest_wave(panel_survey)

        insert_respondents = fn mode, phone_numbers ->
          channel = TestChannel.new()
          channel = insert(:channel, settings: channel |> TestChannel.settings(), type: mode)
          insert_respondents(latest_wave, channel, mode, phone_numbers)
        end

        insert_respondents.("sms", ["1", "2", "3"])
        insert_respondents.("ivr", ["3", "4"])
        terminate_survey(latest_wave)

        # Reload the panel survey. One of its surveys has changed, so it's outdated
        Repo.get!(Ask.PanelSurvey, panel_survey.id)
      end

      defp insert_respondents(survey, channel, mode, phone_numbers) do
        phone_numbers = RespondentGroupAction.loaded_phone_numbers(phone_numbers)
        group = RespondentGroupAction.create(UUID.uuid4(), phone_numbers, survey)
        RespondentGroupAction.update_channels(group.id, [%{"id" => channel.id, "mode" => mode}])
      end
    end
  end
end
