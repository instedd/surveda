defmodule Ask.Runtime.SurveyAction do
  alias Ask.{
    Survey,
    Logger,
    Repo,
    Questionnaire,
    ActivityLog,
    SurveyCanceller,
    Project,
    SystemTime,
    Schedule,
    PanelSurvey
  }

  alias Ask.Runtime.ChannelBroker

  alias Ecto.Multi

  def delete(survey, conn) do
    survey = Repo.preload(survey, [:project])

    multi = Survey.delete_multi(survey)

    log = ActivityLog.delete_survey(survey.project, conn, survey)
    Multi.insert(multi, :log, log) |> Repo.transaction()
  end

  def start(survey) do
    survey =
      survey
      |> Repo.preload([:project])
      |> Repo.preload([:quota_buckets])
      |> Repo.preload([:questionnaires])
      |> Repo.preload(respondent_groups: :channels)

    if survey.state == :ready do
      channels =
        survey.respondent_groups
        |> Enum.flat_map(& &1.channels)
        |> Enum.uniq()

      case prepare_channels(channels) do
        :ok ->
          survey = generate_panel_survey_if_needed(survey)
          perform_start(survey)

        {:error, reason} ->
          Logger.warn(
            "Error when preparing channels for launching survey #{survey.id} (#{reason})"
          )

          {:error, %{survey: survey}}
      end
    else
      Logger.warn("Error when launching survey #{survey.id}. State is not ready ")
      {:error, %{survey: survey}}
    end
  end

  defp generate_panel_survey_if_needed(%{generates_panel_survey: true} = survey) do
    {:ok, panel_survey} = Ask.Runtime.PanelSurvey.create_panel_survey_from_survey(survey)

    PanelSurvey.latest_wave(panel_survey)
    |> Repo.preload(:questionnaires)
  end

  defp generate_panel_survey_if_needed(survey), do: survey

  def stop(survey, conn \\ nil) do
    survey = Repo.preload(survey, [:quota_buckets, :project])

    case [survey.state, survey.locked] do
      [:terminated, false] ->
        # Cancelling a cancelled survey is idempotent.
        # We must not error, because this can happen if a user has the survey
        # UI open with the cancel button, and meanwhile the survey is cancelled
        # from another tab.
        # Cancelling a completed survey should have no effect.
        # We must not error, because this can happen if a user has the survey
        # UI open with the cancel button, and meanwhile the survey finished
        {:ok, %{survey: survey}}

      [:running, false] ->
        changeset =
          Survey.changeset(survey, %{
            state: "cancelling",
            exit_code: 1,
            exit_message: "Cancelled by user"
          })

        multi =
          Multi.new()
          |> Multi.update(:survey, changeset)
          |> Multi.insert(:log, ActivityLog.request_cancel(survey.project, conn, survey))
          |> Repo.transaction()

        case multi do
          {:ok, %{survey: survey}} ->
            survey.project |> Project.touch!()

            %{consumers_pids: consumers_pids, processes: processes} =
              SurveyCanceller.start_cancelling(survey.id)

            {:ok, %{survey: survey, cancellers_pids: consumers_pids, processes: processes}}

          {:error, _, changeset, _} ->
            Logger.warn("Error when stopping survey #{inspect(survey)}")
            {:error, %{changeset: changeset}}
        end

      [_, _] ->
        # Cancelling a pending survey, a survey in any other state or that it
        # is locked, should result in an error.
        Logger.warn("Error when stopping survey #{inspect(survey)}: Wrong state or locked")
        {:error, %{survey: survey}}
    end
  end

  defp perform_start(survey) do
    changeset =
      Survey.changeset(survey, %{
        state: :running,
        started_at: SystemTime.time().now,
        last_window_ends_at: Schedule.last_window_ends_at(survey.schedule)
      })

    case Repo.update(changeset) do
      {:ok, survey} ->
        survey = create_survey_questionnaires_snapshot(survey)

        {:ok, %{survey: survey}}

      {:error, _, changeset, _} ->
        Logger.warn("Error when launching survey: #{inspect(changeset)}")
        {:error, %{changeset: changeset}}
    end
  end

  defp prepare_channels([]), do: :ok

  defp prepare_channels([channel | rest]) do
    runtime_channel = Ask.Channel.runtime_channel(channel)

    case ChannelBroker.prepare(channel.id, runtime_channel) do
      {:ok, _} -> prepare_channels(rest)
      error -> error
    end
  end

  defp create_survey_questionnaires_snapshot(survey) do
    survey = Repo.preload(survey, :project)
    # Create copies of questionnaires
    new_questionnaires =
      Enum.map(survey.questionnaires, fn questionnaire ->
        %{
          questionnaire
          | id: nil,
            snapshot_of_questionnaire: questionnaire,
            questionnaire_variables: [],
            project: survey.project
        }
        |> Repo.preload(:translations)
        |> Repo.insert!()
        |> Questionnaire.recreate_variables!()
      end)

    # Update references in comparisons, if any
    comparisons = survey.comparisons

    comparisons =
      if comparisons do
        comparisons
        |> Enum.map(fn comparison ->
          questionnaire_id = Map.get(comparison, "questionnaire_id")
          snapshot = Enum.find(new_questionnaires, fn q -> q.snapshot_of == questionnaire_id end)
          Map.put(comparison, "questionnaire_id", snapshot.id)
        end)
      else
        comparisons
      end

    survey
    |> Survey.changeset(%{comparisons: comparisons})
    |> Ecto.Changeset.put_assoc(:questionnaires, new_questionnaires)
    |> Repo.update!()
  end
end
