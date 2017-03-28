defmodule Ask.MobileSurveyView do
  use Ask.Web, :view

  def render("show_step.json", %{step: step}) do
    %{step: step }
  end
end
