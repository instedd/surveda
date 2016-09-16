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
      project_id: survey.project_id,
      state: survey.state,
      questionnaire_id: survey.questionnaire_id,
      cutoff: survey.cutoff,
      channels: render_many(survey.channels, Ask.SurveyView, "survey_channel.json", as: :channel )
    }
  end

  def render("survey_detail.json", %{survey: survey}) do
    %{id: survey.id,
      name: survey.name,
      project_id: survey.project_id,
      state: survey.state,
      questionnaire_id: survey.questionnaire_id,
      cutoff: survey.cutoff,
      channels: render_many(survey.channels, Ask.SurveyView, "survey_channel.json", as: :channel ),
      respondents_count: survey.respondents_count
    }
  end

  def render("survey_channel.json", %{channel: channel}) do
    %{
      type: channel.type,
      id: channel.id
    }
  end
end
