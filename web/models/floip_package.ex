defmodule Ask.FloipPackage do
  alias Ask.Survey

  def created_at(survey) do
    survey.started_at
  end

  def modified_at(survey) do
    survey.started_at
  end

  def questions(survey) do
    survey.questionnaires
    |> Enum.flat_map(fn(q) -> q.steps end)
    |> Enum.filter(&floip_question?/1)
  end

  def floip_question?(step) do
    ["multiple-choice", "numeric"]
    |> Enum.member?(step["type"])
  end

  def fields() do
    [
      %{
        "name" => "timestamp",
        "title" => "Timestamp",
        "type" => "datetime"
      },
      %{
        "name" => "row_id",
        "title" => "Row ID",
        "type" => "string"
      },
      %{
        "name" => "contact_id",
        "title" => "Contact ID",
        "type" => "string"
      },
      %{
        "name" => "question_id",
        "title" => "Question ID",
        "type" => "string"
      },
      %{
        "name" => "response_id",
        "title" => "Response ID",
        "type" => "any"
      },
      %{
        "name" => "response_metadata",
        "title" => "Response Metadata",
        "type" => "object"
      }
    ]
  end
end