defmodule Ask.Repo.Migrations.RemoveDummyChoiceFromLanguageStep do
  use Ecto.Migration

  alias Ask.Repo

  defmodule Questionnaire do
    use AskWeb, :model

    schema "questionnaires" do
      field :steps, Ask.Ecto.Type.JSON
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:steps])
    end
  end

  def up do
    for q <- Repo.all(Questionnaire) do
      case q.steps do
        [
          step = %{"type" => "language-selection", "language_choices" => [nil | other_choices]}
          | other_steps
        ] ->
          step = Map.put(step, "language_choices", other_choices)
          steps = [step | other_steps]
          Questionnaire.changeset(q, %{"steps" => steps}) |> Repo.update!()

        _ ->
          :ok
      end
    end
  end

  def down do
    for q <- Repo.all(Questionnaire) do
      case q.steps do
        [step = %{"type" => "language-selection", "language_choices" => choices} | other_steps] ->
          step = Map.put(step, "language_choices", [nil | choices])
          steps = [step | other_steps]
          Questionnaire.changeset(q, %{"steps" => steps}) |> Repo.update!()

        _ ->
          :ok
      end
    end
  end
end
