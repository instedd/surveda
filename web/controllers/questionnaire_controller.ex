defmodule Ask.QuestionnaireController do
  use Ask.Web, :api_controller

  alias Ask.{Questionnaire, Project, JsonSchema, Audio, Logger}

  plug :validate_params when action in [:create, :update]

  def index(conn, %{"project_id" => project_id}) do
    project = conn
    |> load_project(project_id)

    questionnaires = Repo.all(from q in Questionnaire,
      where: q.project_id == ^project.id,
      where: is_nil(q.snapshot_of))

    render(conn, "index.json", questionnaires: questionnaires)
  end

  def create(conn, %{"project_id" => project_id}) do
    project = conn
    |> load_project_for_change(project_id)

    params = conn.assigns[:questionnaire]
    |> Map.put_new("languages", ["en"])
    |> Map.put_new("default_language", "en")

    changeset = project
    |> build_assoc(:questionnaires)
    |> Questionnaire.changeset(params)

    case Repo.insert(changeset) do
      {:ok, questionnaire} ->
        project |> Project.touch!
        questionnaire |> Questionnaire.recreate_variables!
        conn
        |> put_status(:created)
        |> put_resp_header("location", project_questionnaire_path(conn, :index, project_id))
        |> render("show.json", questionnaire: questionnaire)
      {:error, changeset} ->
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

    questionnaire = load_questionnaire(project, id)

    old_valid = questionnaire.valid
    old_modes = questionnaire.modes

    changeset = questionnaire
    |> Questionnaire.changeset(params)

    case Repo.update(changeset) do
      {:ok, questionnaire} ->
        project |> Project.touch!
        questionnaire |> Questionnaire.recreate_variables!
        questionnaire |> Ask.Translation.rebuild

        new_valid = Ecto.Changeset.get_change(changeset, :valid)
        new_modes = Ecto.Changeset.get_change(changeset, :modes)
        if new_valid != old_valid || new_modes != old_modes do
          update_related_surveys(questionnaire)
        end

        render(conn, "show.json", questionnaire: questionnaire)
      {:error, changeset} ->
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

  def delete(conn, %{"project_id" => project_id, "id" => id}) do
    project = conn
    |> load_project_for_change(project_id)

    load_questionnaire(project, id)
    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    |> Repo.delete!

    project |> Project.touch!
    send_resp(conn, :no_content, "")
  end

  def export_zip(conn, %{"project_id" => project_id, "questionnaire_id" => id}) do
    project = conn
    |> load_project(project_id)

    questionnaire = load_questionnaire(project, id)

    audio_ids = collect_steps_audio_ids(questionnaire.steps, [])
    audio_ids = collect_prompt_audio_ids(questionnaire.settings["quota_completed_message"], audio_ids)
    audio_ids = collect_prompt_audio_ids(questionnaire.settings["error_message"], audio_ids)

    audios =
      if length(audio_ids) == 0 do
        []
      else
        (from a in Audio, where: a.uuid in ^audio_ids) |> Repo.all
      end

    audio_files = audios |> Enum.map(fn audio ->
      %{
        "uuid" => audio.uuid,
        "filename" => audio.filename,
        "source" => audio.source,
        "duration" => audio.duration,
      }
    end)
    files = audios |> Enum.map(fn audio ->
      {
        to_charlist("audios/#{audio.uuid}"),
        audio.data,
      }
    end)

    manifest = %{
      name: questionnaire.name,
      modes: questionnaire.modes,
      steps: questionnaire.steps,
      quota_completed_message: questionnaire.settings["quota_completed_message"],
      error_message: questionnaire.settings["error_message"],
      mobile_web_sms_message: questionnaire.settings["mobile_web_sms_message"],
      mobile_web_survey_is_over_message: questionnaire.settings["mobile_web_survey_is_over_message"],
      languages: questionnaire.languages,
      default_language: questionnaire.default_language,
      audio_files: audio_files,
    }

    {:ok, json} = Poison.encode(manifest)

    files = [{'manifest.json', json}, {'audios/', ""} | files]
    {:ok, {'mem', data}} = :zip.create('mem', files, [:memory])

    conn
    |> put_resp_content_type("application/octet-stream")
    |> put_resp_header("content-disposition", "attachment; filename=#{questionnaire.id}.zip")
    |> send_resp(200, data)
  end

  def import_zip(conn, %{"project_id" => project_id, "questionnaire_id" => id, "file" => file}) do
    project = conn
    |> load_project_for_change(project_id)

    questionnaire = load_questionnaire(project, id)

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
      settings: %{
        quota_completed_message: Map.get(manifest, "quota_completed_message"),
        error_message: Map.get(manifest, "error_message"),
        mobile_web_sms_message: Map.get(manifest, "mobile_web_sms_message"),
        mobile_web_survey_is_over_message: Map.get(manifest, "mobile_web_survey_is_over_message")
      },
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
    Repo.one!(from q in Questionnaire,
      where: q.project_id == ^project.id,
      where: q.id == ^id,
      where: is_nil(q.snapshot_of))
  end
end
