defmodule Ask.RespondentView do
  use Ask.Web, :view

  def render("index.json", %{respondents: respondents, respondents_count: respondents_count}) do
    %{data: %{respondents: render_many(respondents, Ask.RespondentView, "respondent.json")}, meta: %{count: respondents_count}}
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
      phone_number: respondent.hashed_number,
      survey_id: respondent.survey_id,
      mode: respondent.mode,
      questionnaire_id: respondent.questionnaire_id,
      responses: render_many(responses, Ask.RespondentView, "response.json", as: :response),
      disposition: respondent.disposition,
      date: case responses do
        [] -> nil
        _ -> responses |>  Enum.map(fn r -> r.updated_at end) |> Enum.max
      end
    }
  end

  def render("response.json", %{response: response}) do
    %{
      name: response.field_name,
      value: response.value
    }
  end

  def render("stats.json", %{stats: %{id: id, respondents_by_state: respondents_by_state, respondents_by_date: respondents_by_date, total_quota: total_quota, cutoff: cutoff, total_respondents: total_respondents}}) do
    %{
      data: %{
        id: id,
        respondents_by_state: respondents_by_state,
        respondents_by_date: render_many(respondents_by_date, Ask.RespondentView, "completed_by_date.json", as: :completed),
        total_quota: total_quota,
        cutoff: cutoff,
        total_respondents: total_respondents
      }
    }
  end

  def render("quotas_stats.json", %{stats: stats}) do
    %{
      data: stats
    }
  end

  def render("completed_by_date.json", %{completed: {date, respondents_count}}) do
    %{
      date: Ecto.Date.cast!(date) |> Ecto.Date.to_string,
      count: respondents_count
    }
  end
end
