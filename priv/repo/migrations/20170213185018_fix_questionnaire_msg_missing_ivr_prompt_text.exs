defmodule Ask.Repo.Migrations.FixQuestionnaireMsgMissingIvrPromptText do
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
    Questionnaire |> Repo.all |> Enum.each(fn questionnaire ->
      questionnaire
      |> Questionnaire.changeset(%{
          quota_completed_msg: fix_prompt(questionnaire.quota_completed_msg),
          error_msg: fix_prompt(questionnaire.error_msg)
        })
      |> Repo.update!
    end)
  end

  def down do
  end

  defp fix_prompt(nil), do: nil

  defp fix_prompt(msg) do
    msg
    |> Map.to_list
    |> Enum.map(fn {lang, prompt} -> {lang, prompt |> fix_lang_prompt} end)
    |> Map.new
  end

  defp fix_lang_prompt(prompt = %{"ivr" => %{"text" => _}}) do
    prompt
  end

  defp fix_lang_prompt(prompt = %{"ivr" => ivr_prompt}) do
    %{prompt | "ivr" => Map.put(ivr_prompt, "text", "")}
  end

  defp fix_lang_prompt(prompt), do: prompt
end
