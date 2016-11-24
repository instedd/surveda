defmodule Mix.Tasks.Ask.ValidateJsonInDb do
  use Mix.Task

  alias Ask.{Questionnaire, Repo, JsonSchema}

  @shortdoc """
  Validates that questionnaires the DB conform to the current schema.json definition.
  """

  defp validate(quiz) do
    {quiz.id, quiz.steps |> JsonSchema.validate(:steps)}
  end

  defp inspect_result({_, []}), do: []
  defp inspect_result({id, validation_result}) do
    Mix.shell.info "######################################################"
    Mix.shell.info "Validation failed for quiz steps (quiz id: #{id})"
    validation_result |> inspect |> Mix.shell.info
  end

  def run(_args) do
    Mix.Task.run "app.start"

    Questionnaire
    |> Repo.all
    |> Enum.map(&validate/1)
    |> Enum.each(&inspect_result/1)
  end
end