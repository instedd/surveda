defmodule Ask.MobileSurveySimulationController do
  alias Ask.Runtime.{QuestionnaireSimulatorStore}
  use Ask.Web, :controller

  def index(conn, %{"respondent_id" => respondent_id, "token" => token}) do
    %{respondent: respondent} = QuestionnaireSimulatorStore.get_respondent_simulation(respondent_id)
    color_style = respondent.session.flow.questionnaire.settings["mobile_web_color_style"]
    render_index(conn, respondent, token, color_style)
  end

  defp render_index(conn, respondent, token, color_style) do
    questionnaire = respondent.session.flow.questionnaire
    default_language = questionnaire.default_language

    {title, mobile_web_intro_message} = case questionnaire do
      %{settings: %{"title" => %{^default_language => some_title}, "mobile_web_intro_message" => intro_message }} ->
        {some_title, intro_message}
      _ ->
        {"Your survey", "Go ahead"}
    end

    conn
    |> put_layout({Ask.LayoutView, "mobile_survey.html"})
    |> render("index.html", respondent_id: respondent.id, token: token, color_style: color_style, title: title, mobile_web_intro_message: mobile_web_intro_message)
  end
end
