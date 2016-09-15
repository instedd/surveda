defmodule Ask.RespondentView do
  use Ask.Web, :view

  def render("index.json", %{respondents: respondents}) do
    %{data: render_many(respondents, Ask.RespondentView, "respondent.json")}
  end

  def render("show.json", %{respondent: respondent}) do
    %{data: render_one(respondent, Ask.RespondentView, "respondent.json")}
  end

  def render("respondent.json", %{respondent: respondent}) do
    %{
      id: respondent.id,
      phone_number: respondent.phone_number,
      survey_id: respondent.survey_id
    }
  end

  def render("stats.json", %{stats: stats}) do
    %{
      data: %{
        pending: stats.pending,
        completed: stats.completed,
        active: stats.active
      }
    }
  end
end
