defmodule Ask.RespondentView do
  use Ask.Web, :view

  def render("index.json", %{respondents: respondents, respondents_count: respondents_count}) do
    %{data: %{respondents: render_many(respondents, Ask.RespondentView, "respondent.json"), respondents_count: respondents_count}}
  end

  def render("show.json", %{respondent: respondent}) do
    %{data: render_one(respondent, Ask.RespondentView, "respondent.json")}
  end

  def render("empty.json", %{respondent: _respondent}) do
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

  def render("stats.json", %{stats: %{id: id, respondents_by_state: respondents_by_state, completed_by_date: %{respondents_by_date: respondents_by_date, target_value: target_value}}}) do
    %{
      data: %{
        id: id,
        respondents_by_state: respondents_by_state,
        completed_by_date: %{
          respondents_by_date: render_many(respondents_by_date, Ask.RespondentView, "completed_by_date.json", as: :completed),
          target_value: target_value
        }
      }
    }
  end

  def render("completed_by_date.json", %{completed: {date, respondents_count}}) do
    %{
      date: Ecto.Date.cast!(date) |> Ecto.Date.to_string,
      count: respondents_count
    }
  end

end
