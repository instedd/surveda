defmodule Ask.Repo.Migrations.UpdateMultipleChoiceResponsesInQuestionnaireSteps do
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

  alias Ask.Repo.Migrations.UpdateMultipleChoiceResponsesInQuestionnaireSteps

  def up do
    Questionnaire |> Repo.all |> Enum.each(fn q ->
      steps = case q.steps do
        nil -> []
        _ ->
          q.steps |> Enum.map(fn step ->
            choices = case Map.get(step, "choices") do
              nil -> []
              _ ->
                step["choices"] |> Enum.map(fn choice ->
                  sms = choice["responses"]
                  responses = if sms do
                                %{"sms" => sms, "ivr" => []}
                              else
                                %{"sms" => [], "ivr" => []}
                              end

                  choice |> Map.put("responses", responses)
                end)
            end
            step |> Map.put("choices", choices)
          end)
      end
      q |> Questionnaire.changeset(%{steps: steps}) |> Repo.update
    end)
  end

  def down do
    Questionnaire |> Repo.all |> Enum.each(fn q ->
      steps = case q.steps do
        nil -> []
        _ ->
          q.steps |> Enum.map(fn step ->
            choices = case Map.get(step, "choices") do
              nil -> []
              _ ->
                step["choices"] |> Enum.map(fn choice ->
                  sms = choice["responses"]["sms"]
                  choice |> Map.put("responses", sms)
                end)
            end
            step |> Map.put("choices", choices)
          end)
      end
      q |> Questionnaire.changeset(%{steps: steps}) |> Repo.update
    end)
  end

end
