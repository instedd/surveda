defmodule Ask.Repo.Migrations.FixQuestionnaireMsgMissingIvrPrompts do
  use Ecto.Migration
  alias Ask.Repo

  defmodule Questionnaire do
    use Ask.Web, :model

    schema "questionnaires" do
      field :modes, Ask.Ecto.Type.StringList
      field :quota_completed_msg, Ask.Ecto.Type.JSON
      field :error_msg, Ask.Ecto.Type.JSON
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:quota_completed_msg, :error_msg])
    end
  end

  def up do
    Questionnaire
    |> Repo.all()
    |> Enum.each(fn questionnaire ->
      ivr_enabled = "ivr" in questionnaire.modes

      questionnaire
      |> Questionnaire.changeset(%{
        quota_completed_msg: fix_prompt(questionnaire.quota_completed_msg, ivr_enabled),
        error_msg: fix_prompt(questionnaire.error_msg, ivr_enabled)
      })
      |> Repo.update!()
    end)
  end

  def down do
  end

  defp fix_prompt(nil, _), do: nil

  defp fix_prompt(msg, ivr_enabled) do
    msg
    |> Map.to_list()
    |> Enum.map(fn {lang, prompt} -> {lang, prompt |> fix_lang_prompt(ivr_enabled)} end)
    |> Map.new()
  end

  defp fix_lang_prompt(prompt = %{"ivr" => nil}, true) do
    %{prompt | "ivr" => %{"text" => "", "audio_source" => "tts"}}
  end

  defp fix_lang_prompt(prompt = %{"ivr" => nil}, false) do
    prompt |> Map.delete("ivr")
  end

  defp fix_lang_prompt(prompt, _), do: prompt
end
