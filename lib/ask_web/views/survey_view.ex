defmodule AskWeb.SurveyView do
  import AskWeb.Router.Helpers
  alias AskWeb.Endpoint
  alias Ask.{Repo, Survey, SystemTime, ScheduleError}

  use AskWeb, :view

  def render("index.json", %{surveys: surveys}) do
    %{data: render_many(surveys, AskWeb.SurveyView, "survey.json")}
  end

  def render("show.json", %{survey: survey}) do
    %{data: render_one(survey, AskWeb.SurveyView, "survey_detail.json")}
  end

  def render("config.json", %{config: config}) do
    config
  end

  def render("stats.json", %{
        success_rate_data: success_rate_data,
        queue_size_data: queue_size_data
      }) do
    %{
      data: %{
        success_rate: success_rate_data.success_rate,
        completion_rate: success_rate_data.completion_rate,
        initial_success_rate: success_rate_data.initial_success_rate,
        estimated_success_rate: success_rate_data.estimated_success_rate,
        exhausted: queue_size_data.exhausted,
        available: queue_size_data.available,
        additional_respondents: queue_size_data.additional_respondents,
        needed_to_complete: queue_size_data.needed_to_complete,
        additional_completes: queue_size_data.additional_completes
      }
    }
  end

  def render("retries_histograms.json", %{histograms: histograms}) do
    %{
      data: histograms
    }
  end

  def render("survey.json", %{survey: survey}) do
    %{
      id: survey.id,
      name: survey.name,
      description: survey.description,
      mode: survey.mode,
      project_id: survey.project_id,
      state: survey.state,
      locked: survey.locked,
      exit_code: survey.exit_code,
      exit_message: survey.exit_message,
      cutoff: survey.cutoff,
      schedule: survey.schedule,
      started_at: format_date(survey.started_at),
      ended_at: format_date(survey.ended_at),
      next_schedule_time: next_schedule_time(survey),
      updated_at: survey.updated_at,
      down_channels: survey.down_channels,
      folder_id: survey.folder_id,
      first_window_started_at: first_window_started_at(survey),
      panel_survey_id: survey.panel_survey_id,
      last_window_ends_at: survey.last_window_ends_at,
      is_deletable: Survey.deletable?(survey),
      is_movable: Survey.movable?(survey),
      generates_panel_survey: survey.generates_panel_survey
    }
  end

  def render("survey_detail.json", %{survey: survey}) do
    survey =
      survey
      |> Repo.preload(:questionnaires)
      |> Repo.preload(:quota_buckets)

    map = %{
      id: survey.id,
      name: survey.name,
      description: survey.description,
      mode: survey.mode,
      project_id: survey.project_id,
      state: survey.state,
      locked: survey.locked,
      exit_code: survey.exit_code,
      exit_message: survey.exit_message,
      questionnaire_ids: questionnaire_ids(survey),
      cutoff: survey.cutoff,
      count_partial_results: survey.count_partial_results,
      schedule: survey.schedule,
      started_at: format_date(survey.started_at),
      ended_at: format_date(survey.ended_at),
      updated_at: survey.updated_at,
      sms_retry_configuration: survey.sms_retry_configuration,
      ivr_retry_configuration: survey.ivr_retry_configuration,
      mobileweb_retry_configuration: survey.mobileweb_retry_configuration,
      fallback_delay: survey.fallback_delay,
      quotas: %{
        buckets:
          render_many(survey.quota_buckets, AskWeb.SurveyView, "survey_bucket.json", as: :bucket),
        vars: survey.quota_vars || []
      },
      links: render_many(survey.links, AskWeb.SurveyView, "link.json", as: :link),
      comparisons: survey.comparisons || [],
      next_schedule_time: next_schedule_time(survey),
      down_channels: survey.down_channels,
      folder_id: survey.folder_id,
      # Preserve the UI from handling the panel survey implementation details
      incentives_enabled: survey.incentives_enabled,
      first_window_started_at: first_window_started_at(survey),
      panel_survey_id: survey.panel_survey_id,
      last_window_ends_at: survey.last_window_ends_at,
      generates_panel_survey: survey.generates_panel_survey
    }

    map =
      if survey.folder_id && Ecto.assoc_loaded?(survey.folder) do
        Map.put(map, :folder, render_folder(survey.folder))
      else
        map
      end

    map =
      if survey.panel_survey_id && Ecto.assoc_loaded?(survey.panel_survey) do
        panel_survey = survey.panel_survey

        Map.put(map, :panel_survey, %{
          id: panel_survey.id,
          project_id: panel_survey.project_id,
          name: panel_survey.name,
          folder:
            if panel_survey.folder_id && Ecto.assoc_loaded?(panel_survey.folder) do
              render_folder(panel_survey.folder)
            end
        })
      else
        map
      end

    if Survey.launched?(survey) || survey.simulation do
      qs =
        survey.questionnaires
        |> Enum.map(fn q ->
          {to_string(q.id), %{id: q.id, name: q.name, valid: true, modes: q.modes}}
        end)
        |> Enum.into(%{})

      Map.put(map, :questionnaires, qs)
    else
      map
    end
  end

  def render("survey_bucket.json", %{bucket: bucket}) do
    condition =
      bucket.condition
      |> Enum.reduce([], fn {store, value}, conditions ->
        [%{"store" => store, "value" => value} | conditions]
      end)

    %{
      "condition" => condition,
      "quota" => bucket.quota,
      "count" => bucket.count
    }
  end

  def render("link.json", %{link: link}) do
    %{
      "name" => link.name,
      "url" => short_link_url(Endpoint, :access, link.hash)
    }
  end

  defp render_folder(folder) do
    %{
      id: folder.id,
      project_id: folder.project_id,
      name: folder.name
    }
  end

  defp format_date(date),
    do: if(date, do: date |> Timex.format!("%FT%T%:z", :strftime), else: nil)

  defp questionnaire_ids(survey = %Survey{}) do
    Enum.map(survey.questionnaires, & &1.id)
  end

  defp next_schedule_time(survey) do
    now = SystemTime.time().now

    next_schedule_time =
      try do
        Survey.next_available_date_time(survey, now)
      rescue
        # If there're surveys with bad schedule configuration, avoid the UI crash
        ScheduleError -> nil
      end

    if next_schedule_time in [now, nil] do
      nil
    else
      next_schedule_time
      |> Timex.Timezone.convert(survey.schedule.timezone)
    end
  end

  defp first_window_started_at(%{first_window_started_at: nil}), do: nil

  defp first_window_started_at(%{
         first_window_started_at: first_window_started_at,
         schedule: %{timezone: timezone}
       }) do
    Timex.Timezone.convert(first_window_started_at, timezone)
    |> format_date
  end
end
