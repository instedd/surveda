defmodule Ask.Runtime.PanelSurvey do
  alias Ask.{Survey, Repo, Schedule, PanelSurvey}
  alias Ask.Runtime.RespondentGroupAction

  defp new_wave_changeset(survey) do
    survey =
      survey
      |> Repo.preload([:project])

    schedule =
      survey.schedule
      |> Schedule.remove_start_date()
      |> Schedule.remove_end_date()

    basic_settings = %{
      project_id: survey.project_id,
      folder_id: survey.folder_id,
      name: PanelSurvey.new_wave_name(),
      description: survey.description,
      mode: survey.mode,
      state: :ready,
      started_at: Timex.now(),
      panel_survey_id: survey.panel_survey_id
    }

    advanced_settings = %{
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

    new_wave = Map.merge(basic_settings, advanced_settings)

    survey.project
    |> Ecto.build_assoc(:surveys)
    |> Survey.changeset(new_wave)
  end

  defp copy_respondents(current_wave, new_wave) do
    current_wave = current_wave |> Repo.preload([:respondent_groups])

    new_respondent_groups_ids =
      RespondentGroupAction.clone_respondents_groups_into(
        current_wave.respondent_groups,
        new_wave
      )
      |> Enum.map(& &1.id)

    new_wave
    |> Repo.preload(:respondent_groups)
    |> Survey.changeset()
    |> Survey.update_respondent_groups(new_respondent_groups_ids)
    |> Repo.update!()
  end

  def create_panel_survey_from_survey(%{
        generates_panel_survey: generates_panel_survey
      })
      when not generates_panel_survey,
      do: {
        :error,
        "Survey must have generates_panel_survey ON to launch to generate a panel survey"
      }

  def create_panel_survey_from_survey(%{
        state: state
      })
      when state != :ready,
      do: {
        :error,
        "Survey must be ready to launch to generate a panel survey"
      }

  def create_panel_survey_from_survey(%{
        panel_survey_id: panel_survey_id
      })
      when panel_survey_id != nil,
      do: {
        :error,
        "Survey can't be a panel survey wave to generate a panel survey"
      }

  # A panel survey only can be created based on a survey
  # This function is responsible for the panel survey creation and its first wave
  # implicated changes:
  # 1. If the panel survey wave is inside a folder, put the panel survey inside it. Remove
  # the survey from its folder. The panel survey waves aren't inside any folder. They are
  # inside folders indirectly, when its panel survey is.
  # 2. Panel survey waves have neither cutoff rules nor comparisons. After creating its
  # panel survey the first wave will remain always a panel survey wave. So the related
  # fields (comparisons, quota_vars, cutoff and count_partial_results) are here set back to their
  # default values, and they won't change again, ever.
  def create_panel_survey_from_survey(survey) do
    {:ok, panel_survey} =
      PanelSurvey.create_panel_survey(%{
        name: PanelSurvey.new_panel_survey_name(survey.name),
        project_id: survey.project_id,
        folder_id: survey.folder_id
      })

    Survey.changeset(survey, %{
      panel_survey_id: panel_survey.id,
      name: PanelSurvey.new_wave_name(),
      folder_id: nil,
      comparisons: [],
      quota_vars: [],
      cutoff: nil,
      count_partial_results: false
    })
    |> Repo.update!()

    {:ok, Repo.get!(PanelSurvey, panel_survey.id)}
  end

  def new_wave(panel_survey) do
    latest_wave =
      PanelSurvey.latest_wave(panel_survey)
      |> Repo.preload([:project])
      |> Repo.preload([:questionnaires])
      |> Repo.preload([:respondent_groups])

    if Survey.terminated?(latest_wave) do
      new_wave = new_wave_from_latest(latest_wave)
      {:ok, %{new_wave: new_wave}}
    else
      {:error, %{error: "Last panel survey wave isn't terminated"}}
    end
  end

  defp new_wave_from_latest(latest) do
    new_wave =
      new_wave_changeset(latest)
      |> Repo.insert!()

    new_wave = copy_respondents(latest, new_wave)
    new_wave
  end
end
