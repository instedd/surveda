defmodule Survey.Helper do
  import Ecto
  import Ecto.Query
  alias Ask.Repo

  def load_survey(%{ assigns: %{project: project} }, survey_id) do
    project
    |> load_survey(survey_id)
  end

  def load_survey(project, survey_id) do
    project
    |> assoc(:surveys)
    |> Repo.get!(survey_id)
  end

  def load_survey_simulation(project, survey_id) do
    project
    |> assoc(:surveys)
    |> where([s], s.simulation)
    |> Repo.get!(survey_id)
  end
end
