defmodule Ask.MobileSurveyController do
  use Ask.Web, :controller
  # import Ask.Router.Helpers

  def index(conn, _params) do
    # user = conn.assigns[:current_user]

    # case {path, user} do
    #   {[], nil} ->
    #     conn |> render("landing.html")
    #   {path, nil} ->
    #     conn |> redirect(to: "#{session_path(conn, :new)}?redirect=/#{Enum.join path, "/"}")
    #   _ ->
    conn
    |> put_layout({Ask.LayoutView, "mobile_survey.html"})
    |> render("index.html", user: nil)
    # end
  end

  def get_step(conn, _params) do
    questionnaire = Repo.get!(Ask.Questionnaire, 95)
    step = Enum.at(questionnaire.steps,2)
    render(conn, "show_step.json", step: step)
  end
end
