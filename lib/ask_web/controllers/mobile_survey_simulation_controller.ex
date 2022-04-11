defmodule AskWeb.MobileSurveySimulationController do
  alias Ask.Runtime.{QuestionnaireSimulator, QuestionnaireSimulatorStore, Reply}
  use AskWeb, :controller

  def index(conn, %{"respondent_id" => respondent_id}) do
    %{respondent: respondent} =
      QuestionnaireSimulatorStore.get_respondent_simulation(respondent_id)

    color_style = respondent.session.flow.questionnaire.settings["mobile_web_color_style"]
    render_index(conn, respondent, color_style)
  end

  defp render_index(conn, respondent, color_style) do
    questionnaire = respondent.session.flow.questionnaire
    default_language = questionnaire.default_language

    {title, mobile_web_intro_message} =
      case questionnaire do
        %{
          settings: %{
            "title" => %{^default_language => some_title},
            "mobile_web_intro_message" => intro_message
          }
        } ->
          {some_title, intro_message}

        _ ->
          {"Your survey", "Go ahead"}
      end

    conn
    |> put_layout({AskWeb.LayoutView, "mobile_survey.html"})
    |> render("index.html",
      respondent_id: respondent.id,
      color_style: color_style,
      title: title,
      mobile_web_intro_message: mobile_web_intro_message
    )
  end

  def get_step(conn, %{"respondent_id" => respondent_id}) do
    {:ok, simulation_step} =
      QuestionnaireSimulator.process_respondent_response(respondent_id, :answer, "mobileweb")

    render_reply(conn, simulation_step.reply)
  end

  def send_reply(conn, %{"respondent_id" => respondent_id, "value" => value}) do
    {:ok, simulation_step} =
      QuestionnaireSimulator.process_respondent_response(respondent_id, value, "mobileweb")

    render_reply(conn, simulation_step.reply)
  end

  defp render_reply(conn, reply),
    do:
      json(conn, %{
        step: Reply.first_step(reply),
        progress: Reply.progress(reply),
        error_message: reply.error_message
      })
end
