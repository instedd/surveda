defmodule Ask.MobileSurveyController do
  use Ask.Web, :controller

  def index(conn, _params) do
    conn
    |> put_layout({Ask.LayoutView, "mobile_survey.html"})
    |> render("index.html", user: nil)
  end

  def get_step(conn, params) do
    step_type = "numeric"

    step = case step_type do
      "language-selection" ->
        %{
          type: "language-selection",
          prompt: "Select a language",
          choices: ["English", "Spanish"]
        }
      "explanation" ->
        %{
          type: "explanation",
          prompt: "This is an explanation step",
        }
      "multiple-choice" ->
        %{
          type: "multiple-choice",
          prompt: "What's your favorite color?",
          choices: ["Red", "Green", "Blue"]
        }
      "numeric" ->
        %{
          type: "numeric",
          prompt: "What's your favorite number (1-10)?",
          min: 1,
          max: 10,
        }
    end

    render(conn, "show_step.json", step: step)
  end
end
