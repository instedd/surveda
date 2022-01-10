defmodule Ask.SurveyController do
  use Ask.Web, :api_controller
  use Ask.Web, :append_assigns_to_action

  import Survey.Helper

  alias Ask.{Project, Folder, Survey, Questionnaire, Logger, RespondentGroup, Respondent, Channel, ShortLink, ActivityLog, RetriesHistogram, ScheduleError, ConflictError}
  alias Ask.Runtime.{Session, SurveyAction}
  alias Ecto.Multi

  plug :assign_project when action in [
    :index,
    :show,
    :stats,
    :retries_histograms,
    :simulation_initial_state,
    :simulation_status,
    :stop_simulation,
  ]
  plug :assign_project_for_change when action in [
    :create,
    :update,
    :set_folder_id,
    :set_name,
    :set_description,
    :delete,
    :launch,
    :simulate_questionanire,
    :create_link,
    :delete_link,
    :refresh_link,
    :stop,
  ]
  plug :assign_project_for_owner when action in [:update_locked_status]

  def index(conn, params, %{project: project}) do
    dynamic = dynamic([s], s.project_id == ^project.id and is_nil(s.folder_id) and is_nil(s.panel_survey_id))

    # Hide simulations from the index
    dynamic = dynamic([s], s.simulation == false and ^dynamic)

    dynamic =
      if params["state"] do
        if params["state"] == "completed" do
          # Same as Survey.succeeded?(s)
          dynamic([s], s.state == "terminated" and s.exit_code == 0 and ^dynamic)
        else
          dynamic([s], s.state == ^params["state"] and ^dynamic)
        end
      else
        dynamic
      end

    dynamic =
      if params["since"] do
        dynamic([s], s.updated_at > ^params["since"] and ^dynamic)
      else
        dynamic
      end

    surveys = Repo.all(from s in Survey,
      preload: [respondent_groups: [respondent_group_channels: :channel]],
      where: ^dynamic)
      |> Enum.map(&(&1 |> Survey.with_down_channels))

    render(conn, "index.json", surveys: surveys)
  end

  def create(conn, params, %{project: project}) do
    folder_id = Map.get(params, "folder_id")

    survey_params = Map.get(params, "survey", %{})
    timezone = Map.get(survey_params, "timezone", Ask.Schedule.default_timezone())
    schedule = Map.merge(Ask.Schedule.default(), %{timezone: timezone})
    generates_panel_survey = Map.get(survey_params, "generates_panel_survey", false)
    props = %{
      "project_id" => project.id,
      "folder_id" => folder_id,
      "name" => "",
      "schedule" => schedule,
      "generates_panel_survey" => generates_panel_survey
    }

    changeset = project
    |> build_assoc(:surveys)
    |> Survey.changeset(props)

    multi = Multi.new
    |> Multi.insert(:survey, changeset)
    |> Multi.run(:log, fn _, %{survey: survey} ->
      ActivityLog.create_survey(project, conn, survey) |> Repo.insert
    end)
    |> Repo.transaction

    case multi do
      {:ok, %{survey: survey}} ->
        project |> Project.touch!

        survey = survey
        |> Repo.preload([:quota_buckets])
        |> Repo.preload(:questionnaires)
        |> Survey.with_links(user_level(project.id, current_user(conn).id))

        conn
        |> put_status(:created)
        |> put_resp_header("location", project_survey_path(conn, :show, project.id, survey))
        |> render("show.json", survey: survey)
      {:error, _, changeset, _} ->
        Logger.warn "Error when creating a survey: #{inspect changeset}"
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(Ask.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}, %{project: project}) do
    survey = load_survey(project, id)
    |> Repo.preload([:quota_buckets])
    |> Repo.preload(:questionnaires)
    |> Repo.preload(:folder)
    |> Repo.preload(panel_survey: [:folder])
    |> Repo.preload(respondent_groups: [respondent_group_channels: :channel])
    |> Survey.with_links(user_level(project.id, current_user(conn).id))
    |> Survey.with_down_channels

    render(conn, "show.json", survey: survey)
  end

  def stats(conn, %{"survey_id" => survey_id}, %{project: project}) do
    survey = load_survey(project, survey_id)

    render(conn, "stats.json", Survey.stats(survey))
  end

  def retries_histograms(conn, %{"survey_id" => id}, %{project: project}) do
    retries_histograms = load_survey(project, id)
    |> RetriesHistogram.survey_histograms()

    render(conn, "retries_histograms.json", %{histograms: retries_histograms})
  end

  def update(conn, %{"id" => id, "survey" => survey_params}, %{project: project}) do
    survey = load_survey(project, id)

    if survey |> Survey.editable? do
      changeset = survey
        |> Repo.preload([:questionnaires])
        |> Repo.preload([:quota_buckets])
        |> Repo.preload(respondent_groups: [respondent_group_channels: :channel])
        |> Survey.changeset(survey_params)
        |> update_questionnaires(survey_params)
        |> Survey.update_state

      changed_properties = changed_properties(changeset)
      rename_log = if :name in changed_properties, do: ActivityLog.rename_survey(project, conn, survey, survey.name, changeset.changes.name), else: nil
      edit_log = if Enum.any?(changed_properties, &(&1 != :name)), do: ActivityLog.edit_survey(project, conn, survey), else: nil

      multi = Multi.new
      |> Multi.run(:survey, fn _, _ ->
        Repo.update(changeset, force: Map.has_key?(changeset.changes, :questionnaires))
      end)
      |> Multi.run(:rename_log, fn _, _ ->
        if rename_log, do: rename_log |> Repo.insert, else: {:ok, nil}
      end)
      |> Multi.run(:edit_log, fn _, _ ->
        if edit_log, do: edit_log |> Repo.insert, else: {:ok, nil}
      end)
      |> Repo.transaction

      case multi do
        {:ok, %{survey: survey}} ->
          project |> Project.touch!
          render(conn, "show.json", survey: survey |> Repo.preload(:questionnaires) |> Survey.with_links(user_level(project.id, current_user(conn).id)))
        {:error, _, changeset, _} ->
          Logger.warn "Error when updating survey: #{inspect changeset}"
          conn
            |> put_status(:unprocessable_entity)
            |> put_view(Ask.ChangesetView)
            |> render("error.json", changeset: changeset)
      end
    else
      conn
        |> put_status(:unprocessable_entity)
        |> put_view(Ask.ChangesetView)
        |> render("error.json", changeset: change(%Survey{}, %{}))
    end
  end

  def set_folder_id(conn, %{"survey_id" => survey_id, "folder_id" => folder_id}, %{project: project}) do
    survey = load_survey(project, survey_id)

    # Panel surveys can belong to a folder, but their waves don't.
    if Survey.belongs_to_panel_survey?(survey), do: raise ConflictError

    old_folder_name = if survey.folder_id, do: Repo.get(Folder, survey.folder_id).name, else: "No Folder"

    new_folder_name = if folder_id, do: (project |> assoc(:folders) |> Repo.get!(folder_id)).name, else: "No Folder"

    result =
      Multi.new()
      |> Multi.update(:set_folder_id, Survey.changeset(survey, %{folder_id: folder_id}))
      |> Multi.insert(:change_folder_log, ActivityLog.change_folder(project, conn, survey, old_folder_name, new_folder_name))
      |> Repo.transaction()

    case result do
      {:ok, _} ->
        send_resp(conn, :no_content, "")

      {:error, _, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(Ask.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end


  def set_name(conn, %{"survey_id" => survey_id, "name" => name}, %{project: project}) do
    survey = load_survey(project, survey_id)

    result =
      Multi.new()
      |> Multi.update(:set_name, Survey.changeset(survey, %{name: name}))
      |> Multi.insert(:rename_log, ActivityLog.rename_survey(project, conn, survey, survey.name, name))
      |> Repo.transaction()

    case result do
      {:ok, _} ->
        send_resp(conn, :no_content, "")

      {:error, _, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(Ask.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def set_description(conn, %{"survey_id" => survey_id, "description" => description}, %{project: project}) do
    survey = load_survey(project, survey_id)

    result =
      Multi.new()
      |> Multi.update(:set_description, Survey.changeset(survey, %{description: description}))
      |> Multi.insert(:change_description_log, ActivityLog.change_survey_description(project, conn, survey, survey.description, description))
      |> Repo.transaction()

    case result do
      {:ok, _} ->
        send_resp(conn, :no_content, "")

      {:error, _, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(Ask.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  defp update_questionnaires(changeset, %{"questionnaire_ids" => questionnaires_ids}) do
    Survey.update_questionnaires(changeset, questionnaires_ids)
  end

  defp update_questionnaires(changeset, _) do
    changeset
  end

  def delete(conn, %{"id" => id}, %{project: project}) do
    survey = load_survey(project, id)

    unless Survey.deletable?(survey), do: raise ConflictError

    case SurveyAction.delete(survey, conn) do
      {:ok, _} ->
        project |> Project.touch!
        send_resp(conn, :no_content, "")
      {:error, _, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(Ask.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def launch(conn, %{"survey_id" => survey_id}, %{project: project}) do
    perform_action = fn survey ->
      try do
        SurveyAction.start(survey)
      rescue
        ScheduleError -> send_resp(conn, :conflict, "Bad schedule configuration")
      end
    end

    activity_log = fn survey ->
      ActivityLog.start(survey.project, conn, survey)
    end

    survey = load_survey(project, survey_id)

    case perform_action.(survey) do
      {:ok, %{survey: survey}} ->
        Project.touch!(survey.project)
        activity_log.(survey) |> Repo.insert!()
        render_survey(conn, survey)

      {:error, %{survey: survey}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render_survey(survey)

      {:error, %{changeset: changeset}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(Ask.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  defp render_survey(conn, survey),
    do:
      render(conn, "show.json",
        survey:
          survey
          |> Survey.with_links(user_level(survey.project_id, current_user(conn).id))
      )

  def simulate_questionanire(conn, %{
    "questionnaire_id" => questionnaire_id,
    "phone_number" => phone_number,
    "mode" => mode,
    "channel_id" => channel_id
  }, %{project: project}) do
    questionnaire = Repo.one!(from q in Questionnaire,
      where: q.project_id == ^project.id,
      where: q.id == ^questionnaire_id)

    channel = Repo.get!(Channel, channel_id)

    survey = %Survey{
      simulation: true,
      project_id: project.id,
      name: questionnaire.name,
      mode: [[mode]],
      state: "ready",
      cutoff: 1,
      schedule: Ask.Schedule.always()}
    |> Ecto.Changeset.change
    |> Repo.insert!

    respondent_group = %RespondentGroup{
      survey_id: survey.id,
      name: "default",
      sample: [phone_number],
      respondents_count: 1}
    |> Ecto.Changeset.change
    |> Repo.insert!

    %Ask.SurveyQuestionnaire{
      survey_id: survey.id,
      questionnaire_id: String.to_integer(questionnaire_id)}
    |> Ecto.Changeset.change
    |> Repo.insert!

    %Ask.RespondentGroupChannel{
      respondent_group_id: respondent_group.id,
      channel_id: channel.id,
      mode: mode}
    |> Ecto.Changeset.change
    |> Repo.insert!

    %Respondent{
      survey_id: survey.id,
      respondent_group_id: respondent_group.id,
      phone_number: phone_number,
      sanitized_phone_number: phone_number,
      canonical_phone_number: phone_number,
      hashed_number: phone_number}
    |> Ecto.Changeset.change
    |> Repo.insert!

    conn
    |> launch(%{"survey_id" => survey.id}, %{project: project})
  end

  def simulation_status(conn, %{"survey_id" => survey_id}, %{project: project}) do
    survey = load_survey_simulation(project, survey_id)

    # The simulation has only one respondent
    respondent = Repo.one!(from r in Respondent,
      where: r.survey_id == ^survey.id)

    responses = respondent
    |> assoc(:responses)
    |> Repo.all
    |> Enum.map(fn response ->
      {response.field_name, response.value}
    end)
    |> Enum.into(%{})

    session = respondent.session
    session =
      if session do
        Session.load(session)
      else
        nil
      end

    {step_id, step_index} =
      if session do
        {
          Session.current_step_id(session),
          case Session.current_step_index(session) do
            {section_index, step_index} -> [section_index, step_index]
            index -> index
          end
        }
      else
        {nil, nil}
      end

    conn
    |> json(%{
      "data" => %{
        "state" => respondent.state,
        "disposition" => respondent.disposition,
        "step_id" => step_id,
        "step_index" => step_index,
        "responses" => responses,
      }
    })
  end

  def stop_simulation(conn, %{"survey_id" => survey_id}, %{project: project}) do
    survey = load_survey_simulation(project, survey_id)

    questionnaire = survey
    |> assoc(:questionnaires)
    |> Repo.one!

    Repo.delete!(survey)
    Project.touch!(project)

    conn
    |> json(%{
      "data" => %{
        "questionnaire_id" => questionnaire.snapshot_of
      }
    })
  end

  def config(conn, _params, _project) do
    render(conn, "config.json", config: Survey.config_rates())
  end

  def create_link(conn, %{"survey_id" => survey_id, "name" => target_name}, %{project: project}) do
    survey = load_survey(project, survey_id)

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

  def refresh_link(conn, %{"survey_id" => survey_id, "name" => target_name}, %{project: project}) do
    if target_name == "interactions" || target_name == "incentives" do
      authorize_admin(project, conn)
    end

    survey = load_survey(project, survey_id)

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

  def delete_link(conn, %{"survey_id" => survey_id, "name" => target_name}, %{project: project}) do
    if target_name == "interactions" || target_name == "incentives" do
      authorize_admin(project, conn)
    end

    survey = load_survey(project, survey_id)

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

  def stop(conn, %{"survey_id" => id}, %{project: project}) do
    survey = load_survey(project, id)

    case SurveyAction.stop(survey, conn) do
      {:ok, %{survey: survey, cancellers_pids: cancellers_pids}} ->
        conn
        |> assign(:processors_pids, cancellers_pids)
        |> render_with_links(survey)

      {:ok, %{survey: survey}} ->
        conn
        |> render_with_links(survey)

      {:error, %{changeset: changeset}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(Ask.ChangesetView)
        |> render("error.json", changeset: changeset)

      {:error, %{survey: survey}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render_with_links(survey)
    end
  end

  defp render_with_links(conn, survey) do
    survey = Repo.preload(survey, :questionnaires)
    user_level = user_level(survey.project_id, current_user(conn).id)
    survey_with_links = Survey.with_links(survey, user_level)
    render(conn, "show.json", survey: survey_with_links)
  end

  def update_locked_status(conn, %{"survey_id" => survey_id, "locked" => locked}, %{project: project}) do
    survey = load_survey(project, survey_id)
    |> Repo.preload([:quota_buckets])
    |> Repo.preload(:questionnaires)
    |> Survey.with_links(user_level(project.id, current_user(conn).id))

    case survey.state do
      "running" ->
        [survey_changeset, activity_log] = case locked do
          true ->
            [Survey.changeset(survey, %{locked: true}), ActivityLog.lock_survey(project, conn, survey)]
          false ->
            [Survey.changeset(survey, %{locked: false}), ActivityLog.unlock_survey(project, conn, survey)]
          _ ->
            [Survey.changeset(%Survey{}), ActivityLog.changeset(%ActivityLog{})]
        end

        multi =
          Multi.new()
          |> Multi.update(:survey, survey_changeset)
          |> Multi.insert(:locked_status_log, activity_log)
          |> Repo.transaction()

        case multi do
          {:ok, %{survey: survey}} ->
            project |> Project.touch!
            render(conn, "show.json", survey: survey)
          {:error, _, changeset, _} ->
            Logger.warn "Error when updating locked status: #{inspect changeset}"
            conn
              |> put_status(:unprocessable_entity)
              |> put_view(Ask.ChangesetView)
              |> render("error.json", changeset: changeset)
        end
      _ ->
        conn
          |> put_status(:unprocessable_entity)
          |> put_view(Ask.ChangesetView)
          |> render("error.json", changeset: change(%Survey{}, %{}))
    end
  end

  def simulation_initial_state(conn, %{"survey_id" => survey_id, "mode" => mode}, %{project: project}) do
    survey = load_survey_simulation(project, survey_id)

    render_initial_state(conn, survey.id, mode)
  end

  defp render_initial_state(conn, survey_id, "mobileweb" = _mode) do
    # The simulation has only one respondent
    respondent = Repo.one!(from r in Respondent,
    where: r.survey_id == ^survey_id)

    response = if (respondent.session) do
      session = Session.load_respondent_session(respondent, true)

      json(conn, %{
        "data" => %{
          "mobile_contact_messages" => Session.mobile_contact_message(session)
        }
      })
    else
      conn
      |> send_resp(:not_found, "")
    end

    response
  end

  defp render_initial_state(conn, _survey_id, _mode) do
    json(conn, %{"data" => %{}})
  end
end
