defmodule Ask.FloipPackageTest do
  use Ask.ModelCase
  alias Ask.StepBuilder

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

  def floip_mappable_steps() do
    [
      StepBuilder.multiple_choice_step(
        id: Ecto.UUID.generate,
        title: "Do you exercise",
        prompt: StepBuilder.prompt(
          sms: StepBuilder.sms_prompt("Do you exercise? Reply 1 for YES, 2 for NO"),
          ivr: StepBuilder.tts_prompt("Do you exercise? Press 1 for YES, 2 for NO")
        ),
        store: "Exercises",
        choices: [
          StepBuilder.choice(value: "Yes", responses: StepBuilder.responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
          StepBuilder.choice(value: "No", responses: StepBuilder.responses(sms: ["No", "N", "2"], ivr: ["2"]))
        ]
      ),
      StepBuilder.numeric_step(
        id: Ecto.UUID.generate,
        title: "Which is the second perfect number?",
        prompt: StepBuilder.prompt(
          sms: StepBuilder.sms_prompt("Which is the second perfect number??"),
          ivr: StepBuilder.tts_prompt("Which is the second perfect number")
          ),
        store: "Perfect Number",
        skip_logic: StepBuilder.default_numeric_skip_logic(),
        alphabetical_answers: false,
        refusal: nil
      )
    ]
  end

  def non_floip_mappable_steps() do
    [
      StepBuilder.flag_step(
          id: Ecto.UUID.generate,
          title: "Let there be rock",
          disposition: "interim partial"),
      StepBuilder.explanation_step(
        id: Ecto.UUID.generate,
        title: "Let there be rock",
        prompt: StepBuilder.prompt(
          sms: StepBuilder.sms_prompt("Is this the last question?")
        ),
        skip_logic: nil
      )
    ]
  end

  test "questions" do
    # Setup
    floip_mappable_steps = floip_mappable_steps()
    other_steps = non_floip_mappable_steps()
    quiz1 = insert(:questionnaire, steps: floip_mappable_steps)
    quiz2 = insert(:questionnaire, steps: other_steps)
    survey = insert(:survey, questionnaires: [quiz1, quiz2])

    # Test
    questions = FloipPackage.questions(survey)

    # Non mappable questions should be left out
    assert length(questions |> Map.to_list) == length(floip_mappable_steps)

    # Questions should be indexed by id,
    # we delegate the details of how they are mapped from steps to
    # FloipPackage.to_floip_question
    floip_mappable_steps
    |> Enum.each(fn(step) -> assert questions[step["id"]] == FloipPackage.to_floip_question(step) end)
  end

  test "convert multiple choice step to_floip_question" do
    multiple_choice_step = StepBuilder.multiple_choice_step(
      id: Ecto.UUID.generate,
      title: "Do you exercise",
      prompt: StepBuilder.prompt(
        sms: StepBuilder.sms_prompt("Do you exercise? Reply 1 for YES, 2 for NO"),
        ivr: StepBuilder.tts_prompt("Do you exercise? Press 1 for YES, 2 for NO")
      ),
      store: "Exercises",
      choices: [
        StepBuilder.choice(value: "Yes", responses: StepBuilder.responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
        StepBuilder.choice(value: "No", responses: StepBuilder.responses(sms: ["No", "N", "2"], ivr: ["2"]))
      ]
    )

    floip_question = multiple_choice_step |> FloipPackage.to_floip_question

    assert floip_question["type"] == "select_one"
    assert floip_question["label"] == "Do you exercise"
    assert floip_question["type_options"] == %{
      "choices" => ["Yes", "No"]
    }
  end

  test "convert numeric step to_floip_question" do
    numeric_step = StepBuilder.numeric_step(
      id: Ecto.UUID.generate,
      title: "Which is the second perfect number?",
      prompt: StepBuilder.prompt(
        sms: StepBuilder.sms_prompt("Which is the second perfect number??"),
        ivr: StepBuilder.tts_prompt("Which is the second perfect number")
        ),
      store: "Perfect Number",
      skip_logic: StepBuilder.default_numeric_skip_logic(),
      alphabetical_answers: false,
      refusal: nil
    )

    floip_question = numeric_step |> FloipPackage.to_floip_question

    assert floip_question["type"] == "numeric"
    assert floip_question["label"] == "Which is the second perfect number?"
    assert floip_question["type_options"] == %{}
  end
end