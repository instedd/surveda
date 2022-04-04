defmodule Ask.Repo.Migrations.MoveUpLanguageSelectionStepPrompt do
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

  def change do
    Questionnaire
    |> Repo.all()
    |> Enum.each(fn q ->
      steps =
        case q.steps do
          nil ->
            []

          _ ->
            q.steps
            |> Enum.map(fn step ->
              case step do
                %{"type" => "language-selection", "prompt" => %{"en" => prompt}} ->
                  step |> Map.put("prompt", prompt)

                _ ->
                  step
              end
            end)
        end

      q |> Questionnaire.changeset(%{steps: steps}) |> Repo.update()
    end)
  end
end
