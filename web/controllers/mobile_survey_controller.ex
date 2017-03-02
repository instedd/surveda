defmodule Ask.MobileSurveyController do
  use Ask.Web, :controller

  def index(conn, _params) do
    conn
    |> put_layout({Ask.LayoutView, "mobile_survey.html"})
    |> render("index.html", user: nil)
  end

  def get_step(conn, params) do
    # For now we show the first step of a random questionnaire
    questionnaire = Ask.Questionnaire |> Repo.all |> Enum.shuffle |> hd
    steps = questionnaire.steps
    if length(steps) == 0 do
      get_step(conn, params)
    else
      step = steps |> hd
      render(conn, "show_step.json", step: step)
    end
  end
end
