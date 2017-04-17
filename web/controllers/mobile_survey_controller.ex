defmodule Ask.MobileSurveyController do
  alias Ask.Runtime.{Broker, Reply}
  alias Ask.Respondent
  use Ask.Web, :controller

  def index(conn, %{"respondent_id" => respondent_id, "token" => token}) do
    if Respondent.token(respondent_id) == token do
      conn
      |> put_layout({Ask.LayoutView, "mobile_survey.html"})
      |> render("index.html", respondent_id: respondent_id)
    else
      raise Ask.UnauthorizedError, conn: conn
    end
  end

  def get_step(conn, %{"respondent_id" => respondent_id}) do
    sync_step(conn, respondent_id, :answer)
  end

  def send_reply(conn, %{"respondent_id" => respondent_id, "value" => value}) do
    sync_step(conn, respondent_id, {:reply, value})
  end

  defp sync_step(conn, respondent_id, value) do
    respondent = Repo.get!(Respondent, respondent_id)
    survey = Repo.preload(respondent, :survey).survey

    step =
      cond do
        survey.state in ["completed", "cancelled"] ->
          questionnaires = Repo.preload(survey, :questionnaires).questionnaires
          questionnaire = Enum.random(questionnaires)
          msg = questionnaire.mobile_web_survey_is_over_message || "The survey is over"
          end_step(msg)
        respondent.state in ["pending", "active", "stalled"] ->
          case Broker.sync_step(respondent, value) do
            {:reply, reply} ->
              reply |> Reply.steps() |> hd
            {:end, {:reply, reply}} ->
              reply |> Reply.steps() |> hd
            :end ->
              end_step()
          end
        true ->
          end_step()
      end

    render(conn, "show_step.json", step: step)
  end

  defp end_step(msg \\ "The survey has ended") do
    %{
      type: "explanation",
      prompts: [msg],
      title: msg,
    }
  end
end
