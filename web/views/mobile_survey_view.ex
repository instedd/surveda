defmodule Ask.MobileSurveyView do
  use Ask.Web, :view

  def render("show_step.json", %{step: step, progress: progress}) do
    %{step: step, progress: progress}
  end
end
