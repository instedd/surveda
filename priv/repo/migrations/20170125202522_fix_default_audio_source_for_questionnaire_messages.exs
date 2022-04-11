defmodule Ask.Repo.Migrations.FixDefaultAudioSourceForQuestionnaireMessages do
  use Ecto.Migration
  alias Ask.Repo

  defmodule Questionnaire do
    use AskWeb, :model

    schema "questionnaires" do
      field :quota_completed_msg, Ask.Ecto.Type.JSON
      field :error_msg, Ask.Ecto.Type.JSON
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:quota_completed_msg, :error_msg])
    end
  end

  defp fix_language_prompt({lang, prompt = %{"ivr" => ivr_prompt}}) do
    {lang, %{prompt | "ivr" => fix_ivr_prompt(ivr_prompt)}}
  end

  defp fix_language_prompt(prompt), do: prompt

  defp fix_ivr_prompt(ivr_prompt = %{"audio_source" => _}) do
    ivr_prompt
  end

  defp fix_ivr_prompt(ivr_prompt = %{}) do
    Map.put(ivr_prompt, "audio_source", "tts")
  end

  defp fix_ivr_prompt(ivr_prompt), do: ivr_prompt

  defp fix(nil), do: nil

  defp fix(prompt) do
    prompt
    |> Enum.map(&fix_language_prompt/1)
    |> Enum.into(%{})
  end

  def up do
    Questionnaire
    |> Repo.all()
    |> Enum.each(fn q ->
      q
      |> Questionnaire.changeset(%{
        quota_completed_msg: fix(q.quota_completed_msg),
        error_msg: fix(q.error_msg)
      })
      |> Repo.update!()
    end)
  end

  def down do
  end
end
