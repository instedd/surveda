defmodule Ask.SurveyLinkController do
  use Ask.Web, :api_controller
  use Ask.Web, :append_assigns_to_action

  import Survey.Helper

  alias Ask.{Survey, Logger, ShortLink, ActivityLog}
  alias Ecto.Multi

  plug :assign_project_for_change
  plug :assign_survey
  plug :put_view, Ask.SurveyView

  def create(conn, %{"name" => target_name}, %{project: project, survey: survey}) do
    {name, target} = case target_name do
      "results" ->
        {
          Survey.link_name(survey, :results),
          project_survey_respondents_results_path(conn, :results, project, survey, %{"_format" => "csv"})
        }
      "incentives" ->
        authorize_admin(project, conn)
        {
          Survey.link_name(survey, :incentives),
          project_survey_respondents_incentives_path(conn, :incentives, project, survey, %{"_format" => "csv"})
        }
      "interactions" ->
        authorize_admin(project, conn)
        {
          Survey.link_name(survey, :interactions),
          project_survey_respondents_interactions_path(conn, :interactions, project, survey, %{"_format" => "csv"})
        }
      "disposition_history" ->
        {
          Survey.link_name(survey, :disposition_history),
          project_survey_respondents_disposition_history_path(conn, :disposition_history, project, survey, %{"_format" => "csv"})
        }
      _ ->
        Logger.warn "Error when creating link #{target_name}"
        conn
        |> put_status(:unprocessable_entity)
        |> send_resp(:no_content, target_name)
    end

    multi = Multi.new
    |> Multi.run(:generate_link, fn _, _ -> ShortLink.generate_link(name, target) end)
    |> Multi.insert(:log, ActivityLog.enable_public_link(project, conn, survey, target_name))
    |> Repo.transaction

    case multi do
      {:ok, %{generate_link: link}} ->
        render(conn, "link.json", link: link)
      {:error, _, changeset, _} ->
        Logger.warn "Error when creating link #{name}"
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(Ask.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def refresh(conn, %{"name" => target_name}, %{project: project, survey: survey}) do
    if target_name == "interactions" || target_name == "incentives" do
      authorize_admin(project, conn)
    end

    link = ShortLink
    |> Repo.get_by(name: Survey.link_name(survey, String.to_atom(target_name)))

    if link do
      multi = Multi.new
      |> Multi.run(:regenerate, fn _, _ -> ShortLink.regenerate(link) end)
      |> Multi.insert(:log, ActivityLog.regenerate_public_link(project, conn, survey, target_name))
      |> Repo.transaction

      case multi do
        {:ok, %{regenerate: new_link}} ->
          render(conn, "link.json", link: new_link)
        {:error, _, changeset, _} ->
          Logger.warn "Error when regenerating results link #{inspect link}"
          conn
          |> put_status(:unprocessable_entity)
          |> put_view(Ask.ChangesetView)
          |> render("error.json", changeset: changeset)
      end
    else
      Logger.warn "Error when regenerating results link #{target_name}"
      conn
      |> put_status(:unprocessable_entity)
      |> send_resp(:no_content, target_name)
    end
  end

  def delete(conn, %{"name" => target_name}, %{project: project, survey: survey}) do
    if target_name == "interactions" || target_name == "incentives" do
      authorize_admin(project, conn)
    end

    link = ShortLink
    |> Repo.get_by(name: Survey.link_name(survey, String.to_atom(target_name)))

    if link do
      multi = Multi.new
      |> Multi.delete(:delete, link)
      |> Multi.insert(:log, ActivityLog.disable_public_link(project, conn, survey, link))
      |> Repo.transaction

      case multi do
        {:ok, _} -> send_resp(conn, :no_content, "")
        {:error, _, changeset, _} ->
          Logger.warn "Error when deleting link #{inspect link}"
          conn
          |> put_status(:unprocessable_entity)
          |> put_view(Ask.ChangesetView)
          |> render("error.json", changeset: changeset)
      end
    else
      conn
      |> send_resp(:not_found, "")
    end
  end

  defp assign_survey(conn, _) do
    %{project: project} = conn.assigns
    %{"survey_id" => survey_id} = conn.params

    survey = load_survey(project, survey_id)
    conn |> assign(:survey, survey)
  end
end
