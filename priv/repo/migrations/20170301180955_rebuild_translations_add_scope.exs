defmodule Ask.Repo.Migrations.RebuildTranslationsAddScope do
  use Ecto.Migration

  defmodule Questionnaire do
    use AskWeb, :model

    schema "questionnaires" do
      field :name, :string
      field :modes, Ask.Ecto.Type.StringList
      field :steps, Ask.Ecto.Type.JSON
      field :quota_completed_msg, Ask.Ecto.Type.JSON
      field :error_msg, Ask.Ecto.Type.JSON
      field :default_language, :string
      field :project_id, :integer
    end
  end

  defmodule Translation do
    use AskWeb, :model

    alias Ask.{Repo, Translation}

    schema "translations" do
      field :mode, :string
      field :scope, :string
      field :source_lang, :string
      field :source_text, :string
      field :target_lang, :string
      field :target_text, :string
      field :project_id, :integer
      field :questionnaire_id, :integer

      Ecto.Schema.timestamps()
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:mode, :scope, :source_lang, :source_text, :target_lang, :target_text])
      |> validate_required([:mode, :scope, :source_lang, :source_text, :target_lang, :target_text])
    end

    def rebuild(questionnaire) do
      lang = questionnaire.default_language

      # First, collect questionnaire translations as
      # {mode, scope, source_lang, source_text, target_lang, target_text}
      new_translations =
        questionnaire.steps
        |> Enum.flat_map(&collect_step_translations(lang, &1))
        |> collect_prompt_entry_translations(
          "quota_completed",
          lang,
          questionnaire.quota_completed_msg
        )
        |> collect_prompt_entry_translations("error", lang, questionnaire.error_msg)

      # Also collect all source texts, so later we can know which ones
      # don't have a translation yet (so we can still use them for autocomplete)
      source_texts =
        questionnaire.steps
        |> Enum.flat_map(&collect_step_source_texts(lang, &1))
        |> collect_prompt_entry_source_texts(
          "quota_completed",
          lang,
          questionnaire.quota_completed_msg
        )
        |> collect_prompt_entry_source_texts("error", lang, questionnaire.error_msg)

      # Only keep source texts that are not already in `new_translations`
      source_texts =
        source_texts
        |> Enum.reject(fn {mode, scope, text} ->
          new_translations
          |> Enum.any?(fn {other_mode, other_scope, other_lang, other_text, _, _} ->
            mode == other_mode && scope == other_scope && lang == other_lang && text == other_text
          end)
        end)

      # Now add these source texts as new translations, without a target language/text
      new_translations =
        source_texts
        |> Enum.reduce(new_translations, fn {mode, scope, text}, translations ->
          [{mode, scope, lang, text, nil, nil} | translations]
        end)

      # Next, collect existing translations (for the migration we use the empty list)
      existing_translations = []

      # Compute which translations need to be added
      additions = compute_additions(existing_translations, new_translations)

      # Insert additions
      additions
      |> Enum.each(fn {mode, scope, source_lang, source_text, target_lang, target_text} ->
        %Translation{
          project_id: questionnaire.project_id,
          questionnaire_id: questionnaire.id,
          mode: mode,
          scope: scope,
          source_lang: source_lang,
          source_text: source_text,
          target_lang: target_lang,
          target_text: target_text
        }
        |> Repo.insert!()
      end)
    end

    defp compute_additions(existing_translations, new_translations) do
      existing_translations =
        existing_translations
        |> Enum.map(fn a ->
          {a.mode, a.scope, a.source_lang, a.source_text, a.target_lang, a.target_text}
        end)

      new_translations
      |> Enum.reject(fn a ->
        existing_translations |> Enum.member?(a)
      end)
      |> Enum.uniq()
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
          |> collect_prompt_entry_translations("prompt", lang, prompt)

        _ ->
          translations
      end
    end

    defp collect_prompt_entry_translations(translations, scope, lang, prompt) do
      case prompt do
        %{^lang => lang_prompt} ->
          translations
          |> collect_prompt_sms_translations(scope, lang, prompt, lang_prompt)
          |> collect_prompt_ivr_translations(scope, lang, prompt, lang_prompt)

        _ ->
          translations
      end
    end

    defp collect_prompt_sms_translations(translations, scope, lang, prompt, lang_prompt) do
      case lang_prompt do
        %{"sms" => text} ->
          if text |> present? do
            prompt
            |> Enum.reduce(translations, fn {other_lang, other_prompt}, translations ->
              if other_lang != lang do
                case other_prompt do
                  %{"sms" => other_text} ->
                    if other_text |> String.trim() |> String.length() == 0 do
                      translations
                    else
                      [{"sms", scope, lang, text, other_lang, other_text} | translations]
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

    defp collect_prompt_ivr_translations(translations, scope, lang, prompt, lang_prompt) do
      case lang_prompt do
        %{"ivr" => %{"text" => text}} ->
          if text |> present? do
            prompt
            |> Enum.reduce(translations, fn {other_lang, other_prompt}, translations ->
              if other_lang != lang do
                case other_prompt do
                  %{"ivr" => %{"text" => other_text}} ->
                    if other_text |> present? do
                      [{"ivr", scope, lang, text, other_lang, other_text} | translations]
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
                  [{"sms", "response", lang, text, other_lang, other_text} | translations]
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
          |> collect_prompt_entry_source_texts("prompt", lang, prompt)

        _ ->
          source_texts
      end
    end

    defp collect_prompt_entry_source_texts(source_texts, scope, lang, prompt) do
      case prompt do
        %{^lang => lang_prompt} ->
          source_texts
          |> collect_prompt_sms_source_texts(scope, lang_prompt)
          |> collect_prompt_ivr_source_texts(scope, lang_prompt)

        _ ->
          source_texts
      end
    end

    defp collect_prompt_sms_source_texts(source_texts, scope, lang_prompt) do
      case lang_prompt do
        %{"sms" => text} ->
          if text |> present? do
            [{"sms", scope, text} | source_texts]
          else
            source_texts
          end

        _ ->
          source_texts
      end
    end

    defp collect_prompt_ivr_source_texts(source_texts, scope, lang_prompt) do
      case lang_prompt do
        %{"ivr" => %{"text" => text}} ->
          if text |> present? do
            [{"ivr", scope, text} | source_texts]
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
            [{"sms", "response", text} | source_texts]
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
      string |> String.trim() |> String.length() > 0
    end
  end

  def up do
    Translation |> Ask.Repo.delete_all()

    Questionnaire
    |> Ask.Repo.all()
    |> Enum.each(fn questionnaire ->
      Translation.rebuild(questionnaire)
    end)
  end

  def down do
    # Nothing to do
  end
end
