defmodule Ask.Runtime.PanelSurvey do
  import Ecto.Query
  alias Ask.{Survey, Repo, Respondent, RespondentGroupChannel, Schedule, PanelSurvey}
  alias Ask.Runtime.RespondentGroupAction

  defp new_ocurrence_changeset(survey) do
    survey =
      survey
      |> Repo.preload([:project])

    schedule =
      survey.schedule
      |> Schedule.remove_start_date()
      |> Schedule.remove_end_date()

    new_ocurrence = %{
      # basic settings
      project_id: survey.project_id,
      folder_id: survey.folder_id,
      name: PanelSurvey.new_occurrence_name(),
      description: survey.description,
      mode: survey.mode,
      state: "ready",
      started_at: Timex.now(),
      panel_survey_id: survey.panel_survey_id,
      # advanced settings
      cutoff: survey.cutoff,
      count_partial_results: survey.count_partial_results,
      schedule: schedule,
      sms_retry_configuration: survey.sms_retry_configuration,
      ivr_retry_configuration: survey.ivr_retry_configuration,
      mobileweb_retry_configuration: survey.mobileweb_retry_configuration,
      fallback_delay: survey.fallback_delay,
      quota_vars: survey.quota_vars,
      quotas: survey.quotas,
      incentives_enabled: survey.incentives_enabled
    }

    survey.project
    |> Ecto.build_assoc(:surveys)
    |> Survey.changeset(new_ocurrence)
  end

  def copy_respondents(current_occurrence, new_occurrence) do
    current_occurrence =
      current_occurrence
      |> Repo.preload([:respondent_groups])

    # TODO: Improve the following respondent group creation logic.
    # For each existing group a new respondent group with the same name is created. Each
    # respondent group has a copy of every respondent (except refused) and channel association
    respondent_group_ids =
      Enum.map(current_occurrence.respondent_groups, fn respondent_group ->
        phone_numbers =
          from(r in Respondent,
            where:
              r.respondent_group_id == ^respondent_group.id and r.disposition != :refused and
                r.disposition != :ineligible,
            select: r.phone_number
          )
          |> Repo.all()
          |> RespondentGroupAction.loaded_phone_numbers()

        new_respondent_group =
          RespondentGroupAction.create(respondent_group.name, phone_numbers, new_occurrence)

        copy_respondent_group_channels(respondent_group, new_respondent_group)
        new_respondent_group.id
      end)

    new_occurrence
    |> Repo.preload(:respondent_groups)
    |> Survey.changeset()
    |> Survey.update_respondent_groups(respondent_group_ids)
    |> Repo.update!()
  end

  def create_panel_survey_from_survey(%{
    generates_panel_survey: generates_panel_survey
    }) when not generates_panel_survey,
    do: {
      :error,
      "Survey must have generates_panel_survey ON to launch to generate a panel survey"
    }

  def create_panel_survey_from_survey(%{
    state: state,
    }) when state != "ready",
    do: {
      :error,
      "Survey must be ready to launch to generate a panel survey"
    }

  def create_panel_survey_from_survey(%{
    panel_survey_id: panel_survey_id
    }) when panel_survey_id != nil,
    do: {
      :error,
      "Survey can't be a panel survey wave to generate a panel survey"
    }

  # A panel survey only can be created based on a survey
  # This function is responsible for the panel survey creation and its first occurrence
  # implicated changes:
  # 1. If the panel survey wave is inside a folder, put the panel survey inside it. Remove
  # the survey from its folder. The panel survey waves aren't inside any folder. They are
  # inside folders indirectly, when its panel survey is.
  # 2. Panel survey occurrences have neither cutoff rules nor comparisons. After creating its
  # panel survey the first occurrence will remain always a panel survey ocurrence. So the related
  # fields (comparisons, quota_vars, cutoff and count_partial_results) are here set back to their
  # default values, and they won't change again, ever.
  def create_panel_survey_from_survey(survey) do
    {:ok, panel_survey} = PanelSurvey.create_panel_survey(%{
      name: PanelSurvey.new_panel_survey_name(survey.name),
      project_id: survey.project_id,
      folder_id: survey.folder_id
    })
    Survey.changeset(survey, %{
      panel_survey_id: panel_survey.id,
      name: PanelSurvey.new_occurrence_name(),
      folder_id: nil,
      comparisons: [],
      quota_vars: [],
      cutoff: nil,
      count_partial_results: false
    })
    |> Repo.update!()
    {:ok, Repo.get!(PanelSurvey, panel_survey.id)}
  end

  defp copy_respondent_group_channels(respondent_group, new_respondent_group) do
    respondent_group =
      respondent_group
      |> Repo.preload(:respondent_group_channels)

    Repo.transaction(fn ->
      Enum.each(
        respondent_group.respondent_group_channels,
        fn respondent_group_channel ->
          RespondentGroupChannel.changeset(
            %RespondentGroupChannel{},
            %{
              respondent_group_id: new_respondent_group.id,
              channel_id: respondent_group_channel.channel_id,
              mode: respondent_group_channel.mode
            }
          )
          |> Repo.insert!()
        end
      )
    end)
  end

  def new_occurrence(panel_survey) do
    latest_occurrence = PanelSurvey.latest_occurrence(panel_survey)
      |> Repo.preload([:project])
      |> Repo.preload([:questionnaires])
      |> Repo.preload([:respondent_groups])

    if Survey.terminated?(latest_occurrence) do
      new_occurrence = new_occurrence_from_latest(latest_occurrence)
      {:ok, %{new_occurrence: new_occurrence}}
    else
      {:error, %{error: "Last panel survey occurrence isn't terminated"}}
    end
  end

  defp new_occurrence_from_latest(latest) do
    new_occurrence = new_ocurrence_changeset(latest)
    |> Repo.insert!()

    new_occurrence = copy_respondents(latest, new_occurrence)
    new_occurrence
  end
end
