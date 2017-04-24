defmodule Ask.MobileSurveyView do
  use Ask.Web, :view

  def render("show_step.json", %{step: step, progress: progress, error_message: error_message}) do
    %{step: step, progress: progress, error_message: error_message}
  end
end
