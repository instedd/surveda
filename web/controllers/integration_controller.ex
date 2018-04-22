defmodule Ask.IntegrationController do
  use Ask.Web, :api_controller
  require Logger
  import PP

  alias Ask.{FloipEndpoint, FloipPackage, FloipPusher}

  def index(conn, %{"project_id" => project_id, "survey_id" => survey_id} = params) do
    integrations = conn
    |> load_project(project_id)
    |> assoc(:surveys)
    |> Repo.get!(survey_id)
    |> assoc(:floip_endpoints)
    |> Repo.all

    render(conn, "index.json", integrations: integrations)
  end

  def create(conn, %{"integration" => integration_params, "survey_id" => survey_id, "project_id" => project_id}) do
    survey =
      conn
      |> load_project(project_id)
      |> assoc(:surveys)
      |> Repo.get!(survey_id)

    case create_integration(conn, integration_params, survey) do
      {:ok, integration} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", project_survey_integration_path(conn, :index, survey.project_id, survey.id))
        |> render("show.json", integration: integration)

      error ->
        Logger.warn "Error when creating a new integration: #{inspect error}"
        conn
        |> put_status(:unprocessable_entity)
        |> render("error.json", error: error)
    end
  end

  defp create_integration(conn, params = %{"name" => name, "uri" => uri, "auth_token" => auth_token}, survey) do
    changeset = FloipEndpoint.changeset(%FloipEndpoint{}, params)
      |> put_assoc(:survey, survey)

    endpoint = apply_changes(changeset)

    case FloipPusher.create_package(survey, endpoint, project_survey_package_responses_url(conn, :responses, survey.project_id, survey.id, survey.floip_package_id)) do
      :ok -> Repo.insert(changeset)

      error ->
        Logger.error "Error creating integration: survey: #{survey.id}, endpoint_uri: #{uri}, response from target service: #{inspect error}"
        {:error, """
        We couldn't create the integration. This could happen because some of the connection details you entered are invalid or the data destination is offline.
        First check if the URI and auth token you entered are correct. If that's the case, navigate to the data destination and make sure it is up and running.
        Once you checked both things, feel free to try again!
        """}
    end
  end
end