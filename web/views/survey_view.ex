defmodule Ask.SurveyView do
  use Ask.Web, :view

  def render("index.json", %{surveys: surveys}) do
    %{data: render_many(surveys, Ask.SurveyView, "survey.json")}
  end

  def render("show.json", %{survey: survey}) do
    %{data: render_one(survey, Ask.SurveyView, "survey_detail.json")}
  end

  def render("survey.json", %{survey: survey}) do
    %{id: survey.id,
      name: survey.name,
      mode: survey.mode,
      project_id: survey.project_id,
      state: survey.state,
      questionnaire_ids: questionnaire_ids(survey),
      cutoff: survey.cutoff,
      channels: render_many(survey.channels, Ask.SurveyView, "survey_channel.json", as: :channel )
    }
  end

  def render("survey_detail.json", %{survey: survey}) do
    started_at = if (survey.started_at), do: survey.started_at |> Timex.format!("%FT%T%:z", :strftime), else: ""
    %{id: survey.id,
      name: survey.name,
      mode: survey.mode,
      project_id: survey.project_id,
      state: survey.state,
      questionnaire_ids: questionnaire_ids(survey),
      cutoff: survey.cutoff,
      channels: render_many(survey.channels, Ask.SurveyView, "survey_channel.json", as: :channel),
      respondents_count: survey.respondents_count,
      schedule_day_of_week: survey.schedule_day_of_week,
      schedule_start_time: survey.schedule_start_time,
      schedule_end_time: survey.schedule_end_time,
      timezone: survey.timezone,
      started_at: started_at,
      updated_at: survey.updated_at,
      sms_retry_configuration: survey.sms_retry_configuration,
      ivr_retry_configuration: survey.ivr_retry_configuration,
      quotas: %{
        buckets: render_many(survey.quota_buckets, Ask.SurveyView, "survey_bucket.json", as: :bucket),
        vars: survey.quota_vars || []
      },
      comparisons: survey.comparisons || []
    }
  end

  def render("survey_channel.json", %{channel: channel}) do
    %{
      type: channel.type,
      id: channel.id
    }
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

  defp questionnaire_ids(survey = %Ask.Survey{}) do
    (survey
    |> Ask.Repo.preload(:questionnaires)).questionnaires
    |> Enum.map(&(&1.id))
  end
end
