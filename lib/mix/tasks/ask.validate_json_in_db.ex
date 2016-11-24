defmodule Mix.Tasks.Ask.ValidateJsonInDb do
  use Mix.Task

  alias Ask.{Questionnaire, Repo, JsonSchema}

  @shortdoc """
  Validates that questionnaires the DB conform to the current schema.json definition.
  """
  defp inspect_result({_, []}), do: []
  defp inspect_result({id, validation_result}) do
    Mix.shell.info "######################################################"
    Mix.shell.info "Validation failed for quiz steps (quiz id: #{id})"
    validation_result |> inspect |> Mix.shell.info
  end

  def run([]), do: run(["schema.json"])
  def run([schema_path]) do
    Mix.Task.run "app.start"

    GenServer.start_link(JsonSchema, [schema_path], name: CustomJsonSchema)

    validate = fn(quiz) -> {quiz.id, quiz.steps |> JsonSchema.validate(:steps, CustomJsonSchema)} end

    Questionnaire
    |> Repo.all
    |> Enum.map(validate)
    |> Enum.each(&inspect_result/1)

    Agent.stop(CustomJsonSchema)
  end
end