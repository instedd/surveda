defmodule Ask.FloipPackageTest do
  use Ask.ModelCase
  use Ask.DummySteps

  alias Ask.FloipPackage

  test "fields" do
    assert FloipPackage.fields == [
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

  test "questions" do
    quiz1 = insert(:questionnaire, steps: @dummy_steps)
    quiz2 = insert(:questionnaire, steps: @dummy_steps)

    survey = insert(:survey, questionnaires: [quiz1, quiz2])

    questions = FloipPackage.questions(survey)

    IO.inspect @dummy_steps

    # Since we're using the same questionnaire twice, I expect the resulting questions mapping
    # to be twice as long.
    assert length(questions) == (@dummy_steps
      |> Enum.filter(&FloipPackage.floip_question?/1)
      |> length
      |> Kernel.*(2))
  end
end