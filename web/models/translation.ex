defmodule Ask.Translation do
  use Ask.Web, :model

  alias Ask.{Repo, Translation}

  schema "translations" do
    field :mode, :string
    field :source_lang, :string
    field :source_text, :string
    field :target_lang, :string
    field :target_text, :string
    belongs_to :project, Ask.Project
    belongs_to :questionnaire, Ask.Questionnaire

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:mode, :source_lang, :source_text, :target_lang, :target_text])
    |> validate_required([:mode, :source_lang, :source_text, :target_lang, :target_text])
  end

  def rebuild(questionnaire) do
    lang = questionnaire.default_language

    # First, collect questionnaire translations as
    # {mode, source_lang, source_text, target_lang, target_text}
    new_translations = questionnaire.steps
    |> Enum.flat_map(&collect_step_translations(lang, &1))
    |> collect_prompt_entry_translations(lang, questionnaire.quota_completed_msg)
    |> collect_prompt_entry_translations(lang, questionnaire.error_msg)

    # Also collect all source texts, so later we can know which ones
    # don't have a translation yet (so we can still use them for autocomplete)
    source_texts = questionnaire.steps
    |> Enum.flat_map(&collect_step_source_texts(lang, &1))
    |> collect_prompt_entry_source_texts(lang, questionnaire.quota_completed_msg)
    |> collect_prompt_entry_source_texts(lang, questionnaire.error_msg)

    # Only keep source texts that are not already in `new_translations`
    source_texts = source_texts
    |> Enum.reject(fn {mode, text} ->
      new_translations
      |> Enum.any?(fn {other_mode, other_lang, other_text, _, _} ->
        mode == other_mode && lang == other_lang && text == other_text
      end)
    end)

    # Now add these source texts as new translations, without a target language/text
    new_translations = source_texts
    |> Enum.reduce(new_translations, fn {mode, text}, translations ->
      [{mode, lang, text, nil, nil} | translations]
    end)

    # Next, collect existing translations
    existing_translations = (from t in Translation,
      where: t.project_id == ^questionnaire.project_id,
      where: t.questionnaire_id == ^questionnaire.id)
    |> Repo.all

    # Compute which translations need to be added
    additions = compute_additions(existing_translations, new_translations)

    # Compute which translations need to be deleted
    deletions = compute_deletions(existing_translations, new_translations)

    # Optimization: the most common scenario is a user editing a translation
    # on a text field. In this case it will count as one addition and
    # one deletion, and it's faster to do an update.
    single_update = single_update?(additions, deletions)
    if single_update do
      hd(deletions)
      |> Translation.changeset(%{target_text: single_update})
      |> Repo.update
    else
      # Delete deletions
      deletions
      |> Enum.each(fn deletion ->
        (from t in Translation, where: t.id == ^deletion.id)
        |> Repo.delete_all
      end)

      # Insert additions
      additions
      |> Enum.each(fn {mode, source_lang, source_text, target_lang, target_text} ->
        %Translation{
          project_id: questionnaire.project_id,
          questionnaire_id: questionnaire.id,
          mode: mode,
          source_lang: source_lang,
          source_text: source_text,
          target_lang: target_lang,
          target_text: target_text,
        } |> Repo.insert
      end)
    end
  end

  defp compute_additions(existing_translations, new_translations) do
    existing_translations = existing_translations
    |> Enum.map(fn a ->
      {a.mode, a.source_lang, a.source_text, a.target_lang, a.target_text}
    end)

    new_translations
    |> Enum.reject(fn a ->
      existing_translations |> Enum.member?(a)
    end)
    |> Enum.uniq
  end

  defp compute_deletions(existing_translations, new_translations) do
    existing_translations
    |> Enum.reject(fn a ->
      new_translations |>
      Enum.member?({a.mode, a.source_lang, a.source_text, a.target_lang, a.target_text})
    end)
  end

  def single_update?([{mode, source_lang, source_text, target_lang, target_text}],
    [%Translation{mode: mode, source_lang: source_lang, source_text: source_text,
    target_lang: target_lang}]) do
    target_text
  end

  def single_update?(_, _) do
    false
  end

  # ------------ #
  # Translations #
  # ------------ #

  defp collect_step_translations(lang, step) do
    []
    |> collect_prompt_translations(lang, step)
    |> collect_choices_translations(lang, step)
  end

  defp collect_prompt_translations(translations, lang, step) do
    case step do
      %{"prompt" => prompt} ->
        translations
        |> collect_prompt_entry_translations(lang, prompt)
      _ ->
        translations
    end
  end

  defp collect_prompt_entry_translations(translations, lang, prompt) do
    case prompt do
      %{^lang => lang_prompt} ->
        translations
        |> collect_prompt_sms_translations(lang, prompt, lang_prompt)
        |> collect_prompt_ivr_translations(lang, prompt, lang_prompt)
      _ ->
        translations
    end
  end

  defp collect_prompt_sms_translations(translations, lang, prompt, lang_prompt) do
    case lang_prompt do
      %{"sms" => text} ->
        if text |> present? do
          prompt
          |> Enum.reduce(translations, fn {other_lang, other_prompt}, translations ->
            if other_lang != lang do
              case other_prompt do
                %{"sms" => other_text} ->
                  if other_text |> String.strip |> String.length == 0 do
                    translations
                  else
                    [{"sms", lang, text, other_lang, other_text} | translations]
                  end
                _ ->
                  translations
              end
            else
              translations
            end
          end)
        else
          translations
        end
      _ ->
        translations
    end
  end

  defp collect_prompt_ivr_translations(translations, lang, prompt, lang_prompt) do
    case lang_prompt do
      %{"ivr" => %{"text" => text}} ->
        if text |> present? do
          prompt
          |> Enum.reduce(translations, fn {other_lang, other_prompt}, translations ->
            if other_lang != lang do
              case other_prompt do
                %{"ivr" => %{"text" => other_text}} ->
                  if other_text |> present? do
                    [{"ivr", lang, text, other_lang, other_text} | translations]
                  else
                    translations
                  end
                _ ->
                  translations
              end
            else
              translations
            end
          end)
        else
          translations
        end
      _ ->
        translations
    end
  end

  defp collect_choices_translations(translations, lang, step) do
    case step do
      %{"choices" => choices} when is_list(choices) ->
        choices
        |> Enum.reduce(translations, fn choice, translations ->
          translations
          |> collect_choice_translations(lang, choice)
        end)
      _ ->
        translations
    end
  end

  defp collect_choice_translations(translations, lang, choice) do
    case choice do
      %{"responses" => %{"sms" => responses = %{^lang => entry}}} ->
        text = entry |> Enum.join(", ")
        if text |> present? do
          responses
          |> Enum.reduce(translations, fn {other_lang, other_entry}, translations ->
            if other_lang != lang do
              other_text = other_entry |> Enum.join(", ")
              if other_text |> present? do
                [{"sms", lang, text, other_lang, other_text} | translations]
              else
                translations
              end
            else
              translations
            end
          end)
        else
          translations
        end
      _ ->
        translations
    end
  end

  # ------------ #
  # Source texts #
  # ------------ #

  defp collect_step_source_texts(lang, step) do
    []
    |> collect_prompt_source_texts(lang, step)
    |> collect_choices_source_texts(lang, step)
  end

  defp collect_prompt_source_texts(source_texts, lang, step) do
    case step do
      %{"prompt" => prompt} ->
        source_texts
        |> collect_prompt_entry_source_texts(lang, prompt)
      _ ->
        source_texts
    end
  end

  defp collect_prompt_entry_source_texts(source_texts, lang, prompt) do
    case prompt do
      %{^lang => lang_prompt} ->
        source_texts
        |> collect_prompt_sms_source_texts(lang_prompt)
        |> collect_prompt_ivr_source_texts(lang_prompt)
      _ ->
        source_texts
    end
  end

  defp collect_prompt_sms_source_texts(source_texts, lang_prompt) do
    case lang_prompt do
      %{"sms" => text} ->
        if text |> present? do
          [{"sms", text} | source_texts]
        else
          source_texts
        end
      _ ->
        source_texts
    end
  end

  defp collect_prompt_ivr_source_texts(source_texts, lang_prompt) do
    case lang_prompt do
      %{"ivr" => %{"text" => text}} ->
        if text |> present? do
          [{"ivr", text} | source_texts]
        else
          source_texts
        end
      _ ->
        source_texts
    end
  end

  defp collect_choices_source_texts(source_texts, lang, step) do
    case step do
      %{"choices" => choices} when is_list(choices) ->
        choices
        |> Enum.reduce(source_texts, fn choice, source_texts ->
          source_texts
          |> collect_choice_source_texts(lang, choice)
        end)
      _ ->
        source_texts
    end
  end

  defp collect_choice_source_texts(source_texts, lang, choice) do
    case choice do
      %{"responses" => %{"sms" => %{^lang => entry}}} ->
        text = entry |> Enum.join(", ")
        if text |> present? do
          [{"sms", text} | source_texts]
        else
          source_texts
        end
      _ ->
        source_texts
    end
  end

  # ----- #
  # Utils #
  # ----- #

  defp present?(string) do
    (string |> String.strip |> String.length) > 0
  end
end
