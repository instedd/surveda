defmodule Ask.FloipController do
  use Ask.Web, :api_controller

  alias Ask.UnauthorizedError
  alias Ask.Survey

  def index(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    survey = load_survey(conn, project_id, survey_id)

    render(conn,
      "index.json",
      packages: Survey.packages(survey),
      self_link: project_survey_packages_url(conn, :index, project_id, survey.id))
  end

  def show(conn, %{"project_id" => project_id, "survey_id" => survey_id, "floip_package_id" => floip_package_id}) do
    survey = load_survey(conn, project_id, survey_id)

    if survey.floip_package_id != floip_package_id || !Survey.has_floip_package?(survey) do
      raise UnauthorizedError, conn: conn
    end

    render(conn,
      "show.json",
      survey: survey,
      self_link: project_survey_package_descriptor_url(conn, :show, project_id, survey_id, floip_package_id),
      responses_link: project_survey_package_responses_url(conn, :responses, project_id, survey_id, floip_package_id))
  end

  defp load_survey(conn, project_id, survey_id) do
    conn
    |> load_project(project_id)
    |> assoc(:surveys)
    |> Repo.get!(survey_id)
  end
end