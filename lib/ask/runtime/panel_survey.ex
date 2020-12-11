defmodule Ask.Runtime.PanelSurvey do
  import Ecto.Query
  alias Ask.{Survey, Repo, Respondent, RespondentGroupChannel}

  def new_ocurrence_changeset(survey) do
    unless Survey.panel_survey?(survey), do: raise("Only panel surveys can be repeated")
    unless survey.latest_panel_survey, do: raise("Only the latest occurrence can be repeated")
    unless Survey.succeeded?(survey), do: raise("Only succeeded surveys can be repeated")

    survey =
      survey
      |> Repo.preload([:project])

    new_ocurrence = %{
      # basic settings
      project_id: survey.project_id,
      folder_id: survey.folder_id,
      name: survey.name,
      description: survey.description,
      mode: survey.mode,
      state: "ready",
      started_at: Timex.now(),
      panel_survey_of: survey.panel_survey_of,
      latest_panel_survey: true,
      # advanced settings
      cutoff: survey.cutoff,
      count_partial_results: survey.count_partial_results,
      schedule: survey.schedule,
      sms_retry_configuration: survey.sms_retry_configuration,
      ivr_retry_configuration: survey.ivr_retry_configuration,
      mobileweb_retry_configuration: survey.mobileweb_retry_configuration,
      fallback_delay: survey.fallback_delay,
      quota_vars: survey.quota_vars,
      quotas: survey.quotas
    }

    questionnaire_ids = Enum.map(survey.questionnaires, fn q -> q.id end)

    survey.project
    |> Ecto.build_assoc(:surveys)
    |> Survey.changeset(new_ocurrence)
    |> Survey.update_questionnaires(questionnaire_ids)
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
            where: r.respondent_group_id == ^respondent_group.id and r.disposition != "refused",
            select: r.phone_number
          )
          |> Repo.all()

        new_respondent_group =
          Ask.Runtime.RespondentGroup.create(respondent_group.name, phone_numbers, new_occurrence)

        copy_respondent_group_channels(respondent_group, new_respondent_group)
        new_respondent_group.id
      end)

    new_occurrence
    |> Repo.preload(:respondent_groups)
    |> Survey.changeset()
    |> Survey.update_respondent_groups(respondent_group_ids)
    |> Repo.update!()
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
end
