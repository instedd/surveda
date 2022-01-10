defmodule Ask.FloipController do
  use Ask.Web, :api_controller

  import Survey.Helper

  alias Ask.UnauthorizedError
  alias Ask.Survey
  alias Ask.FloipPackage

  plug :assign_project

  def index(conn, %{"survey_id" => survey_id}) do
    survey = load_survey(conn, survey_id)

    render(conn,
      "index.json",
      packages: Survey.packages(survey),
      self_link: current_url(conn))
  end

  def show(conn, %{"project_id" => project_id, "survey_id" => survey_id, "floip_package_id" => floip_package_id}) do
    survey = load_survey(conn, survey_id)
    validate_requested_package(conn, survey, floip_package_id)
    descriptor = FloipPackage.descriptor(survey, project_survey_package_responses_url(conn, :responses, project_id, survey_id, floip_package_id))

    render(conn,
      "show.json",
      self_link: current_url(conn),
      descriptor: descriptor)
  end

  def responses(conn, params = %{"project_id" => project_id, "survey_id" => survey_id, "floip_package_id" => floip_package_id}) do
    survey = load_survey(conn, survey_id)
    validate_requested_package(conn, survey, floip_package_id)

    responses_options = FloipPackage.parse_query_params(params)

    {all_responses, first_response, last_response} = FloipPackage.responses(survey, responses_options)

    next_link =
      if last_response do
        options_for_next_page = responses_options |> Map.put(:after_cursor, last_response |> Enum.at(1))
        Ask.Router.Helpers.url(conn) <> conn.request_path <> FloipPackage.query_params(options_for_next_page)
      else
        nil
      end

    previous_link =
      if first_response do
        options_for_previous_page = responses_options |> Map.put(:before_cursor, first_response |> Enum.at(1))
        Ask.Router.Helpers.url(conn) <> conn.request_path <> FloipPackage.query_params(options_for_previous_page)
      else
        nil
      end

    render(conn, "responses.json",
      self_link: current_url(conn),
      next_link: next_link,
      previous_link: previous_link,
      descriptor_link: project_survey_package_descriptor_url(conn, :show, project_id, survey_id, floip_package_id),
      id: floip_package_id,
      responses: all_responses)
  end

  defp validate_requested_package(conn, survey, floip_package_id) do
    if survey.floip_package_id != floip_package_id || !Survey.has_floip_package?(survey) do
      raise UnauthorizedError, conn: conn
    end
  end
end
