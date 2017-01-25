defmodule Mix.Tasks.Ask.ValidateJsonInDb do
  use Mix.Task

  alias Ask.{Questionnaire, Repo, JsonSchema}

  @shortdoc """
  Validates that questionnaires the DB conform to the current schema.json definition.
  """
  defp inspect_result([], _, _), do: []
  defp inspect_result(validation_result, id, field) do
    Mix.shell.info "######################################################"
    Mix.shell.info "Validation failed for quiz #{field} (quiz id: #{id})"
    validation_result |> inspect |> Mix.shell.info
  end

  def run([]), do: run(["schema.json"])
  def run([schema_path]) do
    Mix.Task.run "app.start"

    GenServer.start_link(JsonSchema, [schema_path], name: CustomJsonSchema)

    validate = fn(quiz) ->
      quiz.steps
      |> JsonSchema.validate(:steps, CustomJsonSchema)
      |> inspect_result(quiz.id, "steps")

      if quiz.quota_completed_msg != nil do
        quiz.quota_completed_msg
        |> JsonSchema.validate(:prompt, CustomJsonSchema)
        |> inspect_result(quiz.id, "quota_completed_msg")
      end

    end

    Questionnaire
    |> Repo.all
    |> Enum.map(validate)

    Agent.stop(CustomJsonSchema)
  end
end
