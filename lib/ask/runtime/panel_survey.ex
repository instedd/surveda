defmodule Ask.Runtime.PanelSurvey do
  import Ecto.Query
  alias Ask.{Survey, Repo, Respondent, RespondentGroupChannel}
  alias Ecto.Multi

  def new_ocurrence_changeset(survey) do
    unless Survey.repeatable?(survey), do: raise("Panel survey isn't repeatable")

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

  def delete_multi(survey) do
    Multi.append(pre_delete_multi(survey), Survey.delete_multi(survey))
  end

  defp pre_delete_multi(survey), do: pre_delete_multi(survey, Multi.new)

  # If it's the only one, just drop it
  defp pre_delete_multi(%{latest_panel_survey: true, id: id, panel_survey_of: panel_survey_of} = survey, multi) when id == panel_survey_of do
    Multi.update(multi, :pre_delete_current, pre_delete_current_changeset(survey))
  end

  # Removing the original should make the second one to act as the original
  defp pre_delete_multi(%{latest_panel_survey: false, id: id, panel_survey_of: panel_survey_of} = survey, multi) when id == panel_survey_of do
    following_survey_id = Repo.one(from s in Survey,
    select: s.id,
    where: s.panel_survey_of == ^id and s.id > ^id,
    order_by: [asc: :id],
    limit: 1)
    following_surveys_query = from(s in Survey, where: s.panel_survey_of == ^id and s.id > ^id)

    multi
     |> Multi.update_all(:pre_delete_following, following_surveys_query, set: [panel_survey_of: following_survey_id])
     |> Multi.update(:pre_delete_current, pre_delete_current_changeset(survey))
  end

  # Removing one in the middle is fine
  defp pre_delete_multi(%{latest_panel_survey: false} = survey, multi) do
    Multi.update(multi, :pre_delete_current, pre_delete_current_changeset(survey))
  end

  # Removing the last one should allow the user to create a new incarnation from the previous one from the normal flow.
  defp pre_delete_multi(%{latest_panel_survey: true, panel_survey_of: panel_survey_of, id: id} = survey, multi) do

    previous_survey = Repo.one(from s in Survey,
      where: s.panel_survey_of == ^panel_survey_of and s.id < ^id,
      order_by: [desc: :id],
      limit: 1)

    previous_changeset = Survey.changeset(previous_survey, %{latest_panel_survey: true})

    multi
      |> Multi.update(:pre_delete_previous, previous_changeset)
      |> Multi.update(:pre_delete_current, pre_delete_current_changeset(survey))
  end

  defp pre_delete_current_changeset(survey), do: Survey.changeset(survey, %{panel_survey_of: nil})
end
