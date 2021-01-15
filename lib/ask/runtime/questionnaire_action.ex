defmodule Ask.Runtime.QuestionnaireAction do
  alias Ask.{Questionnaire, Repo, Audio}

  def export(questionnaire) do
    all_questionnaire_steps = Questionnaire.all_steps(questionnaire)
    audio_ids = collect_steps_audio_ids(all_questionnaire_steps, [])
    audio_ids = collect_settings_audio_ids(questionnaire.settings, audio_ids)
    # for each audio: charges it in memory and then streams it.
    audio_resource =
      Stream.resource(
        fn -> audio_ids end,
        fn audio_ids ->
          case audio_ids do
            [id | tail] ->
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
    audio_files =
      Stream.map(audio_resource, fn audio ->
        %{
          "uuid" => audio.uuid,
          "original_filename" => audio.filename,
          "source" => audio.source
        }
      end)

    audio_entries =
      Stream.map(audio_resource, fn audio ->
        # Zstream needs to recieve audio.data as enumerable in order to work, otherwise it throws Protocol.undefined error.
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

    json_entry =
      Stream.map([json], fn json ->
        Zstream.entry("manifest.json", [json])
      end)

    zip_entries = Stream.concat(audio_entries, json_entry)
    # since audio binary data is created as list for Zstream
    # flatten is needed to allow the data to be sent in chunks
    # otherwise the connection sends the whole list as a chunk
    # and times out.
    Zstream.zip(zip_entries)
    |> Stream.flat_map(fn element ->
      case is_list(element) do
        true -> List.flatten(element)
        false -> element
      end
    end)
  end

  defp collect_settings_audio_ids(settings, audio_ids) do
    audio_ids = collect_setting_audio_id(settings["error_message"], audio_ids)
    collect_setting_audio_id(settings["thank_you_message"], audio_ids)
  end

  defp collect_setting_audio_id(nil = _setting, audio_ids) do
    audio_ids
  end

  defp collect_setting_audio_id(setting, audio_ids) do
    collect_lang_prompt_audio_ids(setting, audio_ids)
  end

  defp collect_steps_audio_ids(nil, audio_ids) do
    audio_ids
  end

  defp collect_steps_audio_ids(steps, audio_ids) do
    steps |> Enum.reduce(audio_ids, fn(step, audio_ids) ->
      collect_step_audio_ids(step, audio_ids)
    end)
  end

  defp collect_step_audio_ids(%{"prompt" => %{"ivr" => %{"audio_id" => _audio_id}} = prompt}, audio_ids) do
    collect_prompt_audio_ids(prompt, audio_ids)
  end

  defp collect_step_audio_ids(%{"prompt" => prompt}, audio_ids) do
    collect_lang_prompt_audio_ids(prompt, audio_ids)
  end

  defp collect_step_audio_ids(_, audio_ids) do
    audio_ids
  end

  defp collect_lang_prompt_audio_ids(prompt, audio_ids) do
    prompt |> Enum.reduce(audio_ids, fn {_lang, lang_prompt}, audio_ids ->
      collect_prompt_audio_ids(lang_prompt, audio_ids)
    end)
  end

  defp collect_prompt_audio_ids(%{"ivr" => %{"audio_id" => audio_id} = _prompt}, audio_ids) do
    [audio_id | audio_ids]
  end

  defp collect_prompt_audio_ids(_, audio_ids) do
    audio_ids
  end
end
