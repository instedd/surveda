defmodule Ask.Repo.Migrations.AddPromptSmsToQuestionnaireSteps do
  use Ecto.Migration

  alias Ask.Repo

  defmodule Questionnaire do
    use Ask.Web, :model

    schema "questionnaires" do
      field :steps, Ask.Ecto.Type.JSON
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:steps])
    end
  end

  alias Ask.Repo.Migrations.AddPromptSmsToQuestionnaireSteps.Questionnaire

  def change do
    Questionnaire |> Repo.all |> Enum.each(fn q ->
      steps = case q.steps do
        nil -> []
        _ ->
          q.steps |> Enum.map(fn step ->
            prompt = step["prompt"]
            prompt = if prompt do
                       prompt
                     else
                       %{"sms" => step["title"]}
                     end
            step |> Map.put("prompt", prompt)
          end)
      end
      q |> Questionnaire.changeset(%{steps: steps}) |> Repo.update
    end)
  end
end
