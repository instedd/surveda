defmodule Ask.RespondentView do
  use Ask.Web, :view

  def render("index.json", %{respondents: respondents}) do
    %{data: render_many(respondents, Ask.RespondentView, "respondent.json")}
  end

  def render("show.json", %{respondent: respondent}) do
    %{data: render_one(respondent, Ask.RespondentView, "respondent.json")}
  end

  def render("empty.json", %{respondent: respondent}) do
    %{data: %{}}
  end

  def render("respondent.json", %{respondent: respondent}) do
    responses = respondent.responses
    %{
      id: respondent.id,
      phone_number: respondent.phone_number,
      survey_id: respondent.survey_id,
      responses: render_many(responses, Ask.RespondentView, "response.json", as: :response),
      date: case responses do
        [_ | _] -> Enum.max(Enum.map(responses, fn r -> r.updated_at end))
        _ -> nil
      end
    }
  end

  def render("response.json", %{response: response}) do
    %{
      name: response.field_name,
      value: response.value
    }
  end

  def render("stats.json", %{stats: stats}) do
    %{
      data: %{
        pending: stats.pending,
        completed: stats.completed,
        active: stats.active,
        failed: stats.failed
      }
    }
  end

end
