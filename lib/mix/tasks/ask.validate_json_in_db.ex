defmodule Mix.Tasks.Ask.ValidateJsonInDb do
  use Mix.Task

  alias Ask.{Questionnaire, Repo, JsonSchema}

  @shortdoc """
  Validates that questionnaires the DB conform to the current schema.json definition.
  """
  defp inspect_result([], _), do: []
  defp inspect_result(validation_result, id) do
    Mix.shell.error "######################################################"
    Mix.shell.error "Validation failed for questionnaire (id: #{id})"
    validation_result |> inspect |> Mix.shell.error
  end

  defp validate_questionnaire(quiz) do
    quiz_json = %{
      "steps": quiz.steps,
      "quota_completed_msg": quiz.quota_completed_msg,
      "error_msg": quiz.error_msg
    }

    quiz_json
    |> JsonSchema.validate(:questionnaire, CustomJsonSchema)
    |> inspect_result(quiz.id)
  end

  def run([]), do: run(["schema.json"])
  def run([schema_path]) do
    Mix.Task.run "app.start"

    GenServer.start_link(JsonSchema, [schema_path], name: CustomJsonSchema)

    Questionnaire
    |> Repo.all
    |> Enum.each(&validate_questionnaire/1)

    Agent.stop(CustomJsonSchema)
  end
end
