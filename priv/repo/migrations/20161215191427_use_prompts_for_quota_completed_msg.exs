defmodule Ask.Repo.Migrations.UsePromptsForQuotaCompletedMsg do
  use Ecto.Migration

  alias Ask.Repo

  defmodule Questionnaire do
    use AskWeb, :model

    schema "questionnaires" do
      field :quota_completed_msg, Ask.Ecto.Type.JSON
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:quota_completed_msg])
    end
  end

  def change do
    Questionnaire
    |> Repo.all()
    |> Enum.each(fn q ->
      msg =
        case q.quota_completed_msg do
          nil ->
            nil

          _ ->
            q.quota_completed_msg
            |> Map.to_list()
            |> Enum.map(fn {lang, prompt} ->
              ivr = prompt |> Map.get("ivr")

              ivr =
                if is_binary(ivr) do
                  %{"text" => ivr, "audio_source" => "tts"}
                else
                  ivr
                end

              prompt = prompt |> Map.put("ivr", ivr)
              {lang, prompt}
            end)
            |> Enum.into(%{})
        end

      q |> Questionnaire.changeset(%{quota_completed_msg: msg}) |> Repo.update()
    end)
  end
end
