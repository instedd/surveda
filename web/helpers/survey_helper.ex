defmodule Survey.Helper do
  alias Ask.Repo

  def load_survey(%{ assigns: %{project: project} }, survey_id) do
    project
    |> load_survey(survey_id)
  end

  def load_survey(project, survey_id) do
    project
    |> Ecto.assoc(:surveys)
    |> Repo.get!(survey_id)
  end
end
