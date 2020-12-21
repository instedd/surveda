defmodule Ask.QuestionnaireController do
  use Ask.Web, :api_controller

  alias Ask.{
    Questionnaire,
    SurveyQuestionnaire,
    Survey,
    Project,
    JsonSchema,
    Audio,
    Logger,
    ActivityLog,
    ControllerHelper,
    ErrorView,
    Gettext
  }
  alias Ecto.Multi
  alias Ask.Runtime.QuestionnaireSimulator

  plug :validate_params when action in [:create, :update]
  action_fallback Ask.FallbackController

  def index(conn, %{"project_id" => project_id} = params) do
    project =
      conn
      |> load_project(project_id)

    archived = ControllerHelper.archived_param(params, "url")

    query =
      from(q in Questionnaire,
        where:
          q.project_id == ^project.id and
            is_nil(q.snapshot_of) and
            q.deleted == false
      )

    query = ControllerHelper.filter_archived(query, archived)

    questionnaires = Repo.all(query)

    render(conn, "index.json", questionnaires: questionnaires)
  end

  def create(conn, %{"project_id" => project_id}) do
    project = conn
    |> load_project_for_change(project_id)
    |> validate_project_not_archived(conn)

    params = conn.assigns[:questionnaire]
    |> Map.put_new("languages", ["en"])
    |> Map.put_new("default_language", "en")
    |> Map.put("archived", false)

    changeset = project
    |> build_assoc(:questionnaires)
    |> Questionnaire.changeset(params)

    multi = Multi.new
    |> Multi.insert(:questionnaire, changeset)
    |> Multi.run(:log, fn %{questionnaire: questionnaire} ->
      ActivityLog.create_questionnaire(project, conn, questionnaire) |> Repo.insert
    end)
    |> Repo.transaction

    case multi do
      {:ok, %{questionnaire: questionnaire}} ->
        project |> Project.touch!
        questionnaire |> Questionnaire.recreate_variables!
        conn
        |> put_status(:created)
        |> put_resp_header("location", project_questionnaire_path(conn, :index, project_id))
        |> render("show.json", questionnaire: questionnaire)
      {:error, _, changeset, _} ->
        Logger.warn "Error when creating questionnaire: #{inspect changeset}"
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"project_id" => project_id, "id" => id}) do
    project = conn
    |> load_project(project_id)

    with {:ok, questionnaire} <- load_questionnaire(project, id), do:
      render(conn, "show.json", questionnaire: questionnaire)
  end

  def update(conn, %{"project_id" => project_id, "id" => id}) do
    project = conn
    |> load_project_for_change(project_id)

    params = conn.assigns[:questionnaire]

    questionnaire = load_questionnaire_not_snapshot_nor_archived(project.id, id)

    old_valid = questionnaire.valid
    old_modes = questionnaire.modes

    changeset = questionnaire
    |> Questionnaire.changeset(params)

    multi = Multi.new
    |> Multi.update(:questionnaire, changeset, force: Map.has_key?(changeset.changes, :questionnaires))
    |> Questionnaire.update_activity_logs(conn, project, changeset)
    |> Repo.transaction

    case multi do
      {:ok, %{questionnaire: questionnaire}} ->
        project |> Project.touch!
        questionnaire |> Questionnaire.recreate_variables!
        questionnaire |> Ask.Translation.rebuild

        new_valid = Ecto.Changeset.get_change(changeset, :valid)
        new_modes = Ecto.Changeset.get_change(changeset, :modes)
        if new_valid != old_valid || new_modes != old_modes do
          update_related_surveys(questionnaire)
        end

        render(conn, "show.json", questionnaire: questionnaire)
      {:error, _, changeset, _} ->
        Logger.warn "Error when updating questionnaire: #{inspect changeset}"
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp update_related_surveys(questionnaire) do
    (from s in Ask.Survey,
      join: sq in Ask.SurveyQuestionnaire,
      join: q in Ask.Questionnaire,
      where: q.id == ^questionnaire.id,
      where: sq.questionnaire_id == q.id,
      where: sq.survey_id == s.id)
    |> Repo.all
    |> Enum.each(fn survey ->
      survey
      |> Repo.preload([:questionnaires])
      |> Repo.preload([:quota_buckets])
      |> Repo.preload(respondent_groups: [:respondent_group_channels, :channels])
      |> change
      |> Ask.Survey.update_state
      |> Repo.update!
    end)
  end

  def update_archived_status(conn, %{
        "project_id" => project_id,
        "questionnaire_id" => id,
        "questionnaire" => params
      }) do
    project =
      conn
      |> load_project_for_change(project_id)

    questionnaire = load_questionnaire_not_snapshot(project.id, id)
    archived = ControllerHelper.archived_param(params, "body_json", true)

    update_archived_status(%{
      conn: conn,
      project: project,
      questionnaire: questionnaire,
      archived: archived,
      related_surveys_rejection:
        archived == true and
          Questionnaire.has_related_surveys?(questionnaire.id)
    })
  end

  defp update_archived_status(%{conn: conn, related_surveys_rejection: true}),
    do:
      conn
      |> put_status(:unprocessable_entity)
      |> render(ErrorView, "error.json",
        error_message:
          Gettext.gettext(
            "Cannot archive questionnaire because it's related to one or more surveys"
          )
      )

  defp update_archived_status(%{
         conn: conn,
         project: project,
         questionnaire: questionnaire,
         archived: archived
       }) do
    changeset =
      questionnaire
      |> Questionnaire.changeset(%{archived: archived})

    multi =
      Multi.new()
      |> Multi.update(:questionnaire, changeset)
      |> Multi.run(:log, fn %{questionnaire: questionnaire} ->
        ActivityLog.update_archived_status(project, conn, questionnaire, archived)
        |> Repo.insert()
      end)
      |> Repo.transaction()

    case multi do
      {:ok, %{questionnaire: questionnaire}} ->
        render(conn, "show.json", questionnaire: questionnaire)

      {:error, _, changeset, _} ->
        Logger.warn("Error when archiving/unarchiving questionnaire: #{inspect(changeset)}")

        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"project_id" => project_id, "id" => id}) do
    project = conn
    |> load_project_for_change(project_id)

    changeset = load_questionnaire_not_snapshot(project.id, id)
    |> Questionnaire.changeset(%{deleted: true})

    multi = Multi.new
    |> Multi.update(:questionnaire, changeset)
    |> Multi.run(:log, fn %{questionnaire: questionnaire} ->
      ActivityLog.delete_questionnaire(project, conn, questionnaire) |> Repo.insert
    end)
    |> Repo.transaction

    case multi do
      {:ok, _} ->
        project |> Project.touch!

        surveys = (from s in Survey,
          join: sq in SurveyQuestionnaire, on: sq.questionnaire_id == ^id)
          |> Repo.all

        (from sq in SurveyQuestionnaire, where: sq.questionnaire_id == ^id)
          |> Repo.delete_all

        surveys
        |> Enum.each(fn survey ->
          survey
            |> Repo.preload([:questionnaires])
            |> Repo.preload([:quota_buckets])
            |> Repo.preload(respondent_groups: [:respondent_group_channels, :channels])
            |> change
            |> Survey.update_state
            |> Repo.update!
        end)

        send_resp(conn, :no_content, "")

      {:error, _, changeset, _} ->
        Logger.warn "Error when deleting questionnaire: #{inspect changeset}"
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def export_zip(conn, %{"project_id" => project_id, "questionnaire_id" => id}) do
    project = conn
    |> load_project(project_id)

    questionnaire = load_questionnaire_not_snapshot(project.id, id)
    all_questionnaire_steps = Questionnaire.all_steps(questionnaire)
    audio_ids = collect_steps_audio_ids(all_questionnaire_steps, [])
    audio_ids = collect_prompt_audio_ids(questionnaire.settings["error_message"], audio_ids)
    #for each audio: charges it in memory and then streams it.
    audio_resource = Stream.resource(
      fn -> audio_ids end,
      fn audio_ids ->
        case audio_ids do
        [id |tail] ->
          audio = Repo.get_by(Audio, uuid: id)
          {[audio], tail}
        [] ->
          {:halt, audio_ids}
      end
      end,
      fn _ -> [] end
    )

    # The audio file import is based on this list
    # If it's empty, nothing will be imported
    audio_files = Stream.map(audio_resource, fn audio ->
      %{
        "uuid" => audio.uuid,
        "original_filename" => audio.filename,
        "source" => audio.source
      }
    end)

    audio_entries = Stream.map(audio_resource, fn audio ->
      #Zstream needs to recieve audio.data as enumerable in order to work, otherwise it throws Protocol.undefined error.
      Zstream.entry("audios/" <> Audio.exported_audio_file_name(audio.uuid), [audio.data])
    end)

    manifest = %{
      name: questionnaire.name,
      modes: questionnaire.modes,
      steps: questionnaire.steps,
      quota_completed_steps: questionnaire.quota_completed_steps,
      settings: questionnaire.settings,
      partial_relevant_config: questionnaire.partial_relevant_config,
      languages: questionnaire.languages,
      default_language: questionnaire.default_language,
      audio_files: audio_files
    }
    {:ok, json} = Poison.encode(manifest)
    json_entry = Stream.map([json], fn json ->
      Zstream.entry("manifest.json", [json])
    end)

    zip_entries = Stream.concat(audio_entries, json_entry)
    #since audio binary data is created as list for Zstream
    #flatten is needed to allow the data to be sent in chunks
    #otherwise the connection sends the whole list as a chunk
    #and times out.
    zip_file = Zstream.zip(zip_entries)
               |> Stream.flat_map(
                    fn element ->
                      case is_list(element) do
                        :true -> List.flatten(element)
                        :false -> element
                      end
                    end
                  )
    conn = conn
           |> put_resp_content_type("application/octet-stream")
           |> put_resp_header("content-disposition", "attachment; filename=#{questionnaire.id}.zip")
           |> send_chunked(200)

    zip_file
    |> Enum.reduce_while(
         conn,
         fn (chunk, conn) ->
           case Plug.Conn.chunk(conn, chunk) do
             {:ok, conn} ->
               {:cont, conn}
             {:error, :closed} ->
               {:halt, conn}
           end
         end
       )
  end

  def import_zip(conn, %{"project_id" => project_id, "questionnaire_id" => id, "file" => file}) do
    project = conn
    |> load_project_for_change(project_id)

    questionnaire = load_questionnaire_not_snapshot(project.id, id)

    {:ok, files} = :zip.unzip(to_charlist(file.path), [:memory])

    files = files
    |> Enum.map(fn {filename, data} -> {to_string(filename), data} end)
    |> Enum.into(%{})

    json = files |> Map.get("manifest.json")
    {:ok, manifest} = Poison.decode(json)

    audio_files = manifest |> Map.get("audio_files")
    audio_files |> Enum.each(fn %{"uuid" => uuid, "original_filename" => original_filename, "source" => source} ->
      # Only create audio if it doesn't exist already
      unless Audio |> Repo.get_by(uuid: uuid) do
        data = files |> Map.get("audios/#{Audio.exported_audio_file_name(uuid)}")
        %Audio{uuid: uuid, data: data, filename: original_filename, source: source} |> Repo.insert!
      end
    end)

    questionnaire = questionnaire
    |> Questionnaire.changeset(%{
      name: Map.get(manifest, "name"),
      modes: Map.get(manifest, "modes"),
      steps: Map.get(manifest, "steps"),
      quota_completed_steps: Map.get(manifest, "quota_completed_steps"),
      settings: Map.get(manifest, "settings"),
      partial_relevant_config: Map.get(manifest, "partial_relevant_config"),
      languages: Map.get(manifest, "languages"),
      default_language: Map.get(manifest, "default_language"),
    })
    |> Repo.update!

    render(conn, "show.json", questionnaire: questionnaire)
  end

  def start_simulation(conn, %{"project_id" => project_id, "questionnaire_id" => id}) do
    project = conn |> load_project(project_id)
    mode = conn.params["mode"]
    with {:ok, questionnaire} <- load_questionnaire(project, id),
         {:ok, simulation_response} <- QuestionnaireSimulator.start_simulation(project, questionnaire, mode)
    do
      render(conn, "simulation.json", simulation: simulation_response, mode: mode)
    end
  end

  def sync_simulation(conn, %{"project_id" => project_id}) do
    # Load project to authorize connection
    conn |> load_project(project_id)

    respondent_id = conn.params["respondent_id"]
    response = conn.params["response"]
    with {:ok, simulation_response} <- QuestionnaireSimulator.process_respondent_response(respondent_id, response), do:
      render(conn, "simulation.json", simulation: simulation_response)
  end

  def get_last_simulation_response(conn, %{"project_id" => project_id}) do
    # Load project to authorize connection
    conn |> load_project(project_id)
    respondent_id = conn.params["respondent_id"]
    with {:ok, simulation_response} <- QuestionnaireSimulator.get_last_simulation_response(respondent_id), do:
      render(conn, "simulation.json", simulation: simulation_response)
  end

  defp validate_params(conn, _params) do
    questionnaire = conn.params["questionnaire"]

    case JsonSchema.validate(questionnaire, :questionnaire) do
      [] ->
        conn |> assign(:questionnaire, questionnaire)
      errors ->
        json_errors = errors |> JsonSchema.errors_to_json
        IO.inspect("JSON SCHEMA VALIDATION FAILED")
        IO.inspect("-----------------------------")
        IO.inspect(json_errors)
        conn |> put_status(422) |> json(%{errors: json_errors}) |> halt
    end
  end

  defp collect_steps_audio_ids(nil, audio_ids) do
    audio_ids
  end

  defp collect_steps_audio_ids(steps, audio_ids) do
    steps |> Enum.reduce(audio_ids, fn(step, audio_ids) ->
      collect_step_audio_ids(step, audio_ids)
    end)
  end

  defp collect_step_audio_ids(%{"prompt" => prompt}, audio_ids) do
    collect_prompt_audio_ids(prompt, audio_ids)
  end

  defp collect_step_audio_ids(_, audio_ids) do
    audio_ids
  end

  defp collect_prompt_audio_ids(prompt = %{}, audio_ids) do
    prompt |> Enum.reduce(audio_ids, fn {_lang, lang_prompt}, audio_ids ->
      collect_lang_prompt_audio_ids(lang_prompt, audio_ids)
    end)
  end

  defp collect_prompt_audio_ids(_, audio_ids) do
    audio_ids
  end

  defp collect_lang_prompt_audio_ids(%{"ivr" => %{"audio_id" => audio_id}}, audio_ids) do
    [audio_id | audio_ids]
  end

  defp collect_lang_prompt_audio_ids(_, audio_ids) do
    audio_ids
  end

  defp load_questionnaire(project, id) do
    questionnaire = project
    |> assoc(:questionnaires)
    |> where([q], q.deleted == false)
    |> Repo.get(id)

    case questionnaire do
      nil -> {:error, :not_found}
      _ -> {:ok, questionnaire}
    end
  end

  defp load_questionnaire_not_snapshot(project_id, questionnaire_id) do
    not_deleted_nor_snapshot_query(project_id, questionnaire_id)
    |> Repo.one!()
  end

  defp load_questionnaire_not_snapshot_nor_archived(project_id, questionnaire_id),
    do:
      not_deleted_nor_snapshot_query(project_id, questionnaire_id)
      |> where([q], q.archived == false)
      |> Repo.one!()

  defp not_deleted_nor_snapshot_query(project_id, questionnaire_id),
    do:
      from(q in Questionnaire,
        where:
          q.project_id == ^project_id and
            q.id == ^questionnaire_id and
            q.deleted == false and
            is_nil(q.snapshot_of)
      )
end
