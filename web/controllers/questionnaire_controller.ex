defmodule Ask.QuestionnaireController do
  use Ask.Web, :api_controller

  alias Ask.{Questionnaire, SurveyQuestionnaire, Survey, Project, JsonSchema, Audio, Logger, ActivityLog}
  alias Ecto.Multi

  plug :validate_params when action in [:create, :update]

  def index(conn, %{"project_id" => project_id}) do
    project = conn
    |> load_project(project_id)

    questionnaires = Repo.all(from q in Questionnaire,
      where: q.project_id == ^project.id
        and is_nil(q.snapshot_of)
        and q.deleted == false)

    render(conn, "index.json", questionnaires: questionnaires)
  end

  def create(conn, %{"project_id" => project_id}) do
    project = conn
    |> load_project_for_change(project_id)
    |> validate_project_not_archived(conn)

    params = conn.assigns[:questionnaire]
    |> Map.put_new("languages", ["en"])
    |> Map.put_new("default_language", "en")

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

    questionnaire = load_questionnaire(project, id)

    render(conn, "show.json", questionnaire: questionnaire)
  end

  def update(conn, %{"project_id" => project_id, "id" => id}) do
    project = conn
    |> load_project_for_change(project_id)

    params = conn.assigns[:questionnaire]

    questionnaire = load_questionnaire_not_snapshot(project, id)

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

  def set_description(conn, %{"description" => description , "project_id" => project_id, "questionnaire_id" => id}) do
    project = conn
              |> load_project_for_change(project_id)

    questionnaire = load_questionnaire_not_snapshot(project, id)
    changeset = questionnaire
                |> Questionnaire.changeset(%{description: description})

    multi = Multi.new
            |> Multi.update(:questionnaire, changeset, force: Map.has_key?(changeset.changes, :questionnaires))
            |> Questionnaire.update_activity_logs(conn, project, changeset)
            |> Repo.transaction

    case multi do
      {:ok, %{questionnaire: questionnaire}} ->
        render(conn, "show.json", questionnaire: questionnaire)
      {:error, _, changeset, _} ->
        Logger.warn "Error when updating questionnaire description: #{inspect changeset}"
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"project_id" => project_id, "id" => id}) do
    project = conn
    |> load_project_for_change(project_id)

    changeset = load_questionnaire_not_snapshot(project, id)
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

    questionnaire = load_questionnaire_not_snapshot(project, id)
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
    audio_files_data = %{}
    audio_entries = Stream.map(audio_resource, fn audio ->
      Stream.into(audio, audio_files_data, fn audio ->
        %{
          "uuid" => audio.uuid,
          "filename" => audio.filename,
          "source" => audio.source,
          "duration" => audio.duration,
        }
      end)
      #Zstream needs to recieve audio.data as enumerable in order to work, otherwise it throws Protocol.undefined error.
      Zstream.entry("audios/" <> audio.filename, [audio.data])
    end)

    manifest = %{
      name: questionnaire.name,
      modes: questionnaire.modes,
      steps: questionnaire.steps,
      quota_completed_steps: questionnaire.quota_completed_steps,
      settings: questionnaire.settings,
      languages: questionnaire.languages,
      default_language: questionnaire.default_language,
      audio_files: audio_files_data
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

    questionnaire = load_questionnaire_not_snapshot(project, id)

    {:ok, files} = :zip.unzip(to_charlist(file.path), [:memory])

    files = files
    |> Enum.map(fn {filename, data} -> {to_string(filename), data} end)
    |> Enum.into(%{})

    json = files |> Map.get("manifest.json")
    {:ok, manifest} = Poison.decode(json)

    audio_files = manifest |> Map.get("audio_files")
    audio_files |> Enum.each(fn %{"uuid" => uuid, "filename" => filename, "source" => source, "duration" => duration} ->
      # Only create audio if it doesn't exist already
      unless Audio |> Repo.get_by(uuid: uuid) do
        data = files |> Map.get("audios/#{uuid}")
        %Audio{uuid: uuid, data: data, filename: filename, source: source, duration: duration} |> Repo.insert!
      end
    end)

    questionnaire = questionnaire
    |> Questionnaire.changeset(%{
      name: Map.get(manifest, "name"),
      modes: Map.get(manifest, "modes"),
      steps: Map.get(manifest, "steps"),
      quota_completed_steps: Map.get(manifest, "quota_completed_steps"),
      settings: Map.get(manifest, "settings"),
      languages: Map.get(manifest, "languages"),
      default_language: Map.get(manifest, "default_language"),
    })
    |> Repo.update!

    render(conn, "show.json", questionnaire: questionnaire)
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
    project
    |> assoc(:questionnaires)
    |> where([q], q.deleted == false)
    |> Repo.get!(id)
  end

  defp load_questionnaire_not_snapshot(project, id) do
    Repo.one!(from q in Questionnaire,
      where: q.project_id == ^project.id
        and q.id == ^id
        and q.deleted == false
        and is_nil(q.snapshot_of))
  end
end
