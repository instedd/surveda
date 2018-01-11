defmodule Ask.FloipController do
  use Ask.Web, :api_controller
  alias Ask.Runtime.Session

  alias Ask.Survey

  def index(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    survey = conn
    |> load_project(project_id)
    |> assoc(:surveys)
    |> Repo.get!(survey_id)

    render(conn,
      "index.json",
      packages: Survey.packages(survey),
      self_link: project_survey_packages_url(conn, :index, project_id, survey.id))
  end
end