defmodule AskWeb.SurveyController do
  use AskWeb, :api_controller

  alias Ask.{
    Project,
    Folder,
    Survey,
    Logger,
    ActivityLog,
    QuotaBucket,
    RetriesHistogram,
    ScheduleError
  }

  alias AskWeb.ConflictError
  alias Ask.Runtime.SurveyAction
  alias Ecto.Multi

  def index(conn, %{"project_id" => project_id} = params) do
    project = load_project(conn, project_id)

    dynamic =
      dynamic(
        [s],
        s.project_id == ^project.id and is_nil(s.folder_id) and is_nil(s.panel_survey_id)
      )

    # Hide simulations from the index
    dynamic = dynamic([s], s.simulation == false and ^dynamic)

    dynamic =
      if params["state"] do
        if params["state"] == "completed" do
          # Same as Survey.succeeded?(s)
          dynamic([s], s.state == :terminated and s.exit_code == 0 and ^dynamic)
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

    surveys =
      Repo.all(
        from s in Survey,
          preload: [respondent_groups: [respondent_group_channels: :channel]],
          where: ^dynamic
      )
      |> Enum.map(&(&1 |> Survey.with_down_channels()))

    render(conn, "index.json", surveys: surveys)
  end

  def create(conn, params = %{"project_id" => project_id}) do
    project = load_project_for_change(conn, project_id)

    survey_params = Map.get(params, "survey", %{})
    timezone = Map.get(survey_params, "timezone", Ask.Schedule.default_timezone(project))
    schedule = Map.merge(Ask.Schedule.default(project), %{timezone: timezone})
    generates_panel_survey = Map.get(survey_params, "generates_panel_survey", false)

    props = %{
      "project_id" => project_id,
      "folder_id" => Map.get(params, "folder_id"),
      "name" => "",
      "schedule" => schedule,
      "generates_panel_survey" => generates_panel_survey
    }

    changeset =
      project
      |> build_assoc(:surveys)
      |> Survey.changeset(props)

    insert_survey_and_show_it(changeset, project, conn)
  end

  def duplicate(conn, %{"project_id" => project_id, "survey_id" => source_survey_id}) do
    project = load_project_for_change(conn, project_id)

    source_survey =
      project
      |> load_standalone_survey(source_survey_id)
      |> Repo.preload([:quota_buckets, :questionnaires])

    props = %{
      "project_id" => project_id,
      "folder_id" => source_survey.folder_id,
      "name" => "#{source_survey.name || "Untitled survey"} (duplicate)",
      "description" => source_survey.description,
      "comparisons" => source_survey.comparisons,
      "questionnaire_ids" => editable_questionnaire_ids(source_survey.questionnaires),
      "mode" => source_survey.mode,
      "schedule" => source_survey.schedule,
      "fallback_delay" => source_survey.fallback_delay,
      "ivr_retry_configuration" => source_survey.ivr_retry_configuration,
      "mobileweb_retry_configuration" => source_survey.mobileweb_retry_configuration,
      "sms_retry_configuration" => source_survey.sms_retry_configuration,
      "cutoff" => source_survey.cutoff,
      "quota_vars" => source_survey.quota_vars,
      "count_partial_results" => source_survey.count_partial_results,
    }

    changeset =
      project
      |> build_assoc(:surveys)
      |> Survey.changeset(props)
      |> update_questionnaires(props)
      |> put_assoc(:quota_buckets, quota_buckets_definitions(source_survey.quota_buckets))

    insert_survey_and_show_it(changeset, project, conn)
  end

  defp insert_survey_and_show_it(changeset, project, conn) do
    multi =
      Multi.new()
      |> Multi.insert(:survey, changeset)
      |> Multi.run(:log, fn _, %{survey: survey} ->
        ActivityLog.create_survey(project, conn, survey) |> Repo.insert()
      end)
      |> Repo.transaction()

    case multi do
      {:ok, %{survey: survey}} ->
        project |> Project.touch!()

        survey =
          survey
          |> Repo.preload([:quota_buckets])
          |> Repo.preload(:questionnaires)
          |> Survey.with_links(user_level(project.id, current_user(conn).id))

        conn
        |> put_status(:created)
        |> put_resp_header("location", project_survey_path(conn, :show, project.id, survey))
        |> render("show.json", survey: survey)

      {:error, _, changeset, _} ->
        Logger.warn("Error when creating a survey: #{inspect(changeset)}")

        conn
        |> put_status(:unprocessable_entity)
        |> put_view(AskWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  defp editable_questionnaire_ids(questionnaires), do:
    Enum.map(questionnaires,
      fn %{id: questionnaire_id, snapshot_of: original_questionnaire_id} -> original_questionnaire_id || questionnaire_id end
    )

  # Duplicate the buckets without their counts and quotas
  # This is because duplicate surveys will have different respondent groups,
  # implying different quotas - and no current counts
  defp quota_buckets_definitions(quota_buckets), do:
    Enum.map(quota_buckets, fn %{condition: condition} ->
      %QuotaBucket{condition: condition}
    end
    )

  def show(conn, %{"project_id" => project_id, "id" => id}) do
    survey =
      conn
      |> load_project(project_id)
      |> load_survey(id)
      |> Repo.preload([:quota_buckets])
      |> Repo.preload(:questionnaires)
      |> Repo.preload(:folder)
      |> Repo.preload(panel_survey: [:folder])
      |> Repo.preload(respondent_groups: [respondent_group_channels: :channel])
      |> Survey.with_links(user_level(project_id, current_user(conn).id))
      |> Survey.with_down_channels()

    render(conn, "show.json", survey: survey)
  end

  def stats(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    stats =
      conn
      |> load_project(project_id)
      |> load_survey(survey_id)
      |> Survey.stats()

    render(conn, "stats.json", stats)
  end

  def retries_histograms(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    retries_histograms =
      conn
      |> load_project(project_id)
      |> load_survey(survey_id)
      |> RetriesHistogram.survey_histograms()

    render(conn, "retries_histograms.json", %{histograms: retries_histograms})
  end

  def update(conn, %{"project_id" => project_id, "id" => id, "survey" => survey_params}) do
    project = load_project_for_change(conn, project_id)
    survey = load_survey(project, id)

    if survey |> Survey.editable?() do
      changeset =
        survey
        |> Repo.preload([:questionnaires])
        |> Repo.preload([:quota_buckets])
        |> Repo.preload(respondent_groups: [respondent_group_channels: :channel])
        |> Survey.changeset(survey_params)
        |> update_questionnaires(survey_params)
        |> Survey.update_state()

      changed_properties = changed_properties(changeset)

      rename_log =
        if :name in changed_properties,
          do:
            ActivityLog.rename_survey(project, conn, survey, survey.name, changeset.changes.name),
          else: nil

      edit_log =
        if Enum.any?(changed_properties, &(&1 != :name)),
          do: ActivityLog.edit_survey(project, conn, survey),
          else: nil

      multi =
        Multi.new()
        |> Multi.run(:survey, fn _, _ ->
          Repo.update(changeset, force: Map.has_key?(changeset.changes, :questionnaires))
        end)
        |> Multi.run(:rename_log, fn _, _ ->
          if rename_log, do: rename_log |> Repo.insert(), else: {:ok, nil}
        end)
        |> Multi.run(:edit_log, fn _, _ ->
          if edit_log, do: edit_log |> Repo.insert(), else: {:ok, nil}
        end)
        |> Repo.transaction()

      case multi do
        {:ok, %{survey: survey}} ->
          project |> Project.touch!()

          render(conn, "show.json",
            survey:
              survey
              |> Repo.preload(:questionnaires)
              |> Survey.with_links(user_level(project_id, current_user(conn).id))
          )

        {:error, _, changeset, _} ->
          Logger.warn("Error when updating survey: #{inspect(changeset)}")

          conn
          |> put_status(:unprocessable_entity)
          |> put_view(AskWeb.ChangesetView)
          |> render("error.json", changeset: changeset)
      end
    else
      conn
      |> put_status(:unprocessable_entity)
      |> put_view(AskWeb.ChangesetView)
      |> render("error.json", changeset: change(%Survey{}, %{}))
    end
  end

  def set_folder_id(conn, %{
        "project_id" => project_id,
        "survey_id" => survey_id,
        "folder_id" => folder_id
      }) do
    project = load_project_for_change(conn, project_id)
    survey = load_survey(project, survey_id)

    # Panel surveys can belong to a folder, but their waves don't.
    if Survey.belongs_to_panel_survey?(survey), do: raise(ConflictError)

    old_folder_name =
      if survey.folder_id, do: Repo.get(Folder, survey.folder_id).name, else: "No Folder"

    new_folder_name =
      if folder_id,
        do: (project |> assoc(:folders) |> Repo.get!(folder_id)).name,
        else: "No Folder"

    result =
      Multi.new()
      |> Multi.update(:set_folder_id, Survey.changeset(survey, %{folder_id: folder_id}))
      |> Multi.insert(
        :change_folder_log,
        ActivityLog.change_folder(project, conn, survey, old_folder_name, new_folder_name)
      )
      |> Repo.transaction()

    case result do
      {:ok, _} ->
        send_resp(conn, :no_content, "")

      {:error, _, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(AskWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def set_name(conn, %{"project_id" => project_id, "survey_id" => survey_id, "name" => name}) do
    project = load_project_for_change(conn, project_id)
    survey = load_survey(project, survey_id)

    result =
      Multi.new()
      |> Multi.update(:set_name, Survey.changeset(survey, %{name: name}))
      |> Multi.insert(
        :rename_log,
        ActivityLog.rename_survey(project, conn, survey, survey.name, name)
      )
      |> Repo.transaction()

    case result do
      {:ok, _} ->
        send_resp(conn, :no_content, "")

      {:error, _, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(AskWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def set_description(conn, %{
        "project_id" => project_id,
        "survey_id" => survey_id,
        "description" => description
      }) do
    project = load_project_for_change(conn, project_id)
    survey = load_survey(project, survey_id)

    result =
      Multi.new()
      |> Multi.update(:set_description, Survey.changeset(survey, %{description: description}))
      |> Multi.insert(
        :change_description_log,
        ActivityLog.change_survey_description(
          project,
          conn,
          survey,
          survey.description,
          description
        )
      )
      |> Repo.transaction()

    case result do
      {:ok, _} ->
        send_resp(conn, :no_content, "")

      {:error, _, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(AskWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  defp update_questionnaires(changeset, %{"questionnaire_ids" => questionnaires_ids}) do
    Survey.update_questionnaires(changeset, questionnaires_ids)
  end

  defp update_questionnaires(changeset, _) do
    changeset
  end

  def delete(conn, %{"project_id" => project_id, "id" => id}) do
    project = load_project_for_change(conn, project_id)
    survey = load_survey(project, id)

    unless Survey.deletable?(survey), do: raise(ConflictError)

    case SurveyAction.delete(survey, conn) do
      {:ok, _} ->
        project |> Project.touch!()
        send_resp(conn, :no_content, "")

      {:error, _, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(AskWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def launch(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    perform_action = fn survey ->
      try do
        SurveyAction.start(survey)
      rescue
        ScheduleError -> send_resp(conn, :conflict, "Bad schedule configuration")
      end
    end

    project = load_project_for_change(conn, project_id)
    survey = load_survey(project, survey_id)

    case perform_action.(survey) do
      {:ok, %{survey: survey}} ->
        Project.touch!(survey.project)
        ActivityLog.start(project, conn, survey) |> Repo.insert!()
        render_survey(conn, survey)

      {:error, %{survey: survey}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render_survey(survey)

      {:error, %{changeset: changeset}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(AskWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  defp render_survey(conn, survey) do
    level = user_level(survey.project_id, current_user(conn).id)
    render(conn, "show.json", survey: Survey.with_links(survey, level))
  end

  def config(conn, _params) do
    render(conn, "config.json", config: Survey.config_rates())
  end

  def stop(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    survey =
      conn
      |> load_project_for_change(project_id)
      |> load_survey(survey_id)

    case SurveyAction.stop(survey, conn) do
      {:ok, %{survey: survey}} ->
        conn
        |> render_with_links(survey)

      {:error, %{changeset: changeset}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(AskWeb.ChangesetView)
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

  def update_locked_status(conn, %{
        "project_id" => project_id,
        "survey_id" => survey_id,
        "locked" => locked
      }) do
    project = load_project_for_owner(conn, project_id)

    survey =
      project
      |> load_survey(survey_id)
      |> Repo.preload([:quota_buckets])
      |> Repo.preload(:questionnaires)
      |> Survey.with_links(user_level(project_id, current_user(conn).id))

    case survey.state do
      :running ->
        [survey_changeset, activity_log] =
          case locked do
            true ->
              [
                Survey.changeset(survey, %{locked: true}),
                ActivityLog.lock_survey(project, conn, survey)
              ]

            false ->
              [
                Survey.changeset(survey, %{locked: false}),
                ActivityLog.unlock_survey(project, conn, survey)
              ]

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
            project |> Project.touch!()
            render(conn, "show.json", survey: survey)

          {:error, _, changeset, _} ->
            Logger.warn("Error when updating locked status: #{inspect(changeset)}")

            conn
            |> put_status(:unprocessable_entity)
            |> put_view(AskWeb.ChangesetView)
            |> render("error.json", changeset: changeset)
        end

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(AskWeb.ChangesetView)
        |> render("error.json", changeset: change(%Survey{}, %{}))
    end
  end

  def active_channels(conn, %{"provider" => provider, "base_url" => base_url}) do
    surveys = Survey.with_active_channels(current_user(conn).id, provider, base_url)

    render(conn, "index.json", surveys: surveys)
  end

  defp load_survey(project, survey_id) do
    project
    |> assoc(:surveys)
    |> Repo.get!(survey_id)
  end

  defp load_standalone_survey(project, survey_id) do
    load_survey(project, survey_id)
    |> validate_standalone_survey
  end

  # TODO: this seems to clash with the definition in `Survey.belongs_to_panel_survey?`
  defp validate_standalone_survey(%{generates_panel_survey: true}), do: raise ConflictError
  defp validate_standalone_survey(survey = %{panel_survey_id: nil}), do: survey
  defp validate_standalone_survey(%{panel_survey_id: _id}), do: raise ConflictError

end
