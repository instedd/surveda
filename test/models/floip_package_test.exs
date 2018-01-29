defmodule Ask.FloipPackageTest do
  use Ask.ModelCase
  alias Ask.{StepBuilder, FloipPackage}

  test "fields" do
    # The FLOIP spec demands that these fields are printed in
    # every descriptor verbatim.
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

  # A list of steps to create questionnaire fixtures.
  # This list has one example of multiple choice step and
  # a numeric one. Currently we do not export any other
  # step types, as the mapping to FLOIP is unclear.
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

  # A list of steps to create questionnaire fixtures.
  # This list has one example of flag step and
  # an explanation one. We use them to ensure
  # that non-FLOIP-translatable steps won't
  # "leak" to FLOIP APIs
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

  describe "questions" do
    test "list" do
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

      # Questions should be indexed by their corresponding "store" name,
      # because Surveda links responses to variables more strongly than
      # questions.
      # We delegate the details of how they are mapped from steps to
      # FloipPackage.to_floip_question, though.
      floip_mappable_steps
      |> Enum.each(fn(step) -> assert questions[step["store"]] == FloipPackage.to_floip_question(step) end)
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
      assert floip_question["type_options"] == %{ "choices" => ["Yes", "No"] }
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

  describe "responses" do
    def insert_survey do
      floip_mappable_steps = floip_mappable_steps()
      other_steps = non_floip_mappable_steps()
      quiz1 = insert(:questionnaire, steps: floip_mappable_steps)
      quiz2 = insert(:questionnaire, steps: other_steps)
      insert(:survey, questionnaires: [quiz1, quiz2])
    end

    def insert_respondent(survey, number) do
      insert(:respondent, survey: survey, hashed_number: number)
    end

    def insert_response(respondent, field_name, response) do
      insert(:response,
        respondent: respondent,
        field_name: field_name,
        value: response,
        inserted_at: Timex.Ecto.DateTime.autogenerate)
    end

    def assert_same(floip_response, db_response) do
      assert Enum.at(floip_response, 1) == db_response.id
    end

    test "survey with no responses" do
      survey = insert_survey()
      responses = FloipPackage.responses(survey)
      assert responses == []
    end

    test "survey with one response" do
      # Setup
      survey = insert_survey()
      respondent_1 = insert_respondent(survey, "1234")
      db_response = insert_response(respondent_1, "Exercises", "Yes")

      # Test
      responses = FloipPackage.responses(survey)

      # Assertions
      assert length(responses) == 1

      response = responses |> hd

      assert length(response) == 6
      {:ok, response_timestamp, _} = DateTime.from_iso8601(Enum.at(response, 0))
      assert DateTime.compare(response_timestamp, db_response.inserted_at) == :eq
      assert Enum.at(response, 1) == db_response.id
      assert Enum.at(response, 2) == db_response.respondent.hashed_number
      assert Enum.at(response, 3) == "Exercises"
      assert Enum.at(response, 4) == "Yes"
      assert Enum.at(response, 5) == %{}
    end

    test "survey with many responses" do
      # Setup
      survey = insert_survey()
      respondent_1 = insert_respondent(survey, "1234")
      db_response_1 = insert_response(respondent_1, "Exercises", "Yes")
      respondent_2 = insert_respondent(survey, "5678")
      db_response_2 = insert_response(respondent_2, "Exercises", "No")

      # Test
      responses = FloipPackage.responses(survey)

      # Assertions
      assert length(responses) == 2

      response_1 = responses |> Enum.at(0)
      response_2 = responses |> Enum.at(1)

      # We already cover that the whole structure is sound in another
      # test, here we just focus on ensuring all responses are included
      assert_same(response_1, db_response_1)
      assert_same(response_2, db_response_2)
    end
  end
end