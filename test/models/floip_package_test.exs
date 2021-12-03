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
        "name" => "session_id",
        "title" => "Session ID",
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
      insert(:survey, questionnaires: [quiz1, quiz2], started_at: DateTime.utc_now)
    end

    def insert_respondent(survey, number) do
      insert(:respondent, survey: survey, hashed_number: number)
    end

    def insert_response(respondent, field_name, response, id, inserted_at) do
      insert(:response,
        respondent: respondent,
        field_name: field_name,
        value: response,
        inserted_at: inserted_at,
        id: id)
    end
    def insert_response(respondent, field_name, response, id \\ nil) do
      insert_response(respondent, field_name, response, id, DateTime.utc_now)
    end

    def assert_same(floip_response, db_response) do
      assert Enum.at(floip_response, 1) == db_response.id
    end

    test "survey with no responses" do
      survey = insert_survey()
      {responses, nil, nil} = FloipPackage.responses(survey)
      assert responses == []
    end

    test "survey with one response" do
      # Setup
      survey = insert_survey()
      respondent_1 = insert_respondent(survey, "1234")
      db_response = insert_response(respondent_1, "Exercises", "Yes")

      # Test
      {responses, only_response, only_response} = FloipPackage.responses(survey)

      # Assertions
      assert length(responses) == 1

      response = responses |> hd

      assert length(response) == 7
      {:ok, response_timestamp, _} = DateTime.from_iso8601(Enum.at(response, 0))

      # 0 -- both arguments represent the same date when coalesced to the same timezone.
      inserted_at = DateTime.truncate(db_response.inserted_at, :second)
      assert DateTime.compare(response_timestamp, inserted_at) == :eq

      assert Enum.at(response, 1) == db_response.id
      assert Enum.at(response, 2) == db_response.respondent.hashed_number
      assert Enum.at(response, 3) == db_response.respondent.hashed_number
      assert Enum.at(response, 4) == "Exercises"
      assert Enum.at(response, 5) == "Yes"
      assert Enum.at(response, 6) == %{}
    end

    test "survey with many responses" do
      # Setup
      survey = insert_survey()
      respondent_1 = insert_respondent(survey, "1234")
      db_response_1 = insert_response(respondent_1, "Exercises", "Yes")
      respondent_2 = insert_respondent(survey, "5678")
      db_response_2 = insert_response(respondent_2, "Exercises", "No")

      # Test
      {responses, first_response, last_response} = FloipPackage.responses(survey)

      # Assertions
      assert length(responses) == 2

      response_1 = responses |> Enum.at(0)
      response_2 = responses |> Enum.at(1)

      assert response_1 == first_response
      assert response_2 == last_response

      # We already cover that the whole structure is sound in another
      # test, here we just focus on ensuring all responses are included
      assert_same(response_1, db_response_1)
      assert_same(response_2, db_response_2)
    end

    # FLOIP actually doesn't mandate this, but it does state:
    #
    # "A unique value identifying an individual Response within the Flow Results package.
    # The value must be unique within the entire package. Row IDs may be an integer or a string.
    # (The purpose of Row IDs is for systems offering paginated access to Responses within a Package.
    # Although the rows may not be ordered by Row ID, software hosting data at paginated
    # URLs must maintain an internal ordering based on Row IDs,
    # such that it is possible to return the next X rows after a given Row ID.)"
    #
    # The most natural implementation of this for Surveda is to simply order by id.
    test "responses are ordered by id" do
      # Setup
      survey = insert_survey()
      # Notice we first insert with a higher id and then with a lower id,
      # we want to force this to ensure there's an order by clause doing it's
      # job for this test.
      respondent_1 = insert_respondent(survey, "1234")
      oldest_response = insert_response(respondent_1, "Exercises", "Yes", 2)
      respondent_2 = insert_respondent(survey, "5678")
      newest_response = insert_response(respondent_2, "Exercises", "No", 1)

      # Test
      {responses, first_response, last_response} = FloipPackage.responses(survey)

      # Assertions
      assert length(responses) == 2

      response_1 = responses |> Enum.at(0)
      response_2 = responses |> Enum.at(1)

      assert response_1 == first_response
      assert response_2 == last_response

      assert_same(response_1, newest_response)
      assert_same(response_2, oldest_response)
    end

    test "return responses after a timestamp" do
      # Setup
      survey = insert_survey()
      respondent_1 = insert_respondent(survey, "1234")
      _db_response_1 = insert_response(respondent_1, "Exercises", "Yes", 1, DateTime.from_iso8601("2000-01-01T01:02:03Z") |> elem(1))
      respondent_2 = insert_respondent(survey, "5678")
      db_response_2 = insert_response(respondent_2, "Exercises", "No", 2, DateTime.from_iso8601("2001-01-01T01:02:03Z") |> elem(1))

      june_2000_iso8601 = %DateTime{
        year: 2000, month: 6, day: 1,
        zone_abbr: "UTC", hour: 1, minute: 2, second: 3, microsecond: {0, 0},
        utc_offset: 3600, std_offset: 0, time_zone: "Etc/UTC"
      } |> DateTime.to_iso8601

      # Test
      {responses, only_response, only_response} = FloipPackage.responses(survey, start_timestamp: june_2000_iso8601)

      # Assertions
      assert length(responses) == 1
      assert_same(responses |> Enum.at(0), db_response_2)
    end

    test "return responses before a timestamp" do
      # Setup
      survey = insert_survey()
      respondent_1 = insert_respondent(survey, "1234")
      db_response_1 = insert_response(respondent_1, "Exercises", "Yes", 1, DateTime.from_iso8601("2000-01-01T01:02:03Z") |> elem(1))
      respondent_2 = insert_respondent(survey, "5678")
      _db_response_2 = insert_response(respondent_2, "Exercises", "No", 2, DateTime.from_iso8601("2001-01-01T01:02:03Z") |> elem(1))

      june_2000_iso8601 = %DateTime{
        year: 2000, month: 6, day: 1,
        zone_abbr: "UTC", hour: 1, minute: 2, second: 3, microsecond: {0, 0},
        utc_offset: 3600, std_offset: 0, time_zone: "Etc/UTC"
      } |> DateTime.to_iso8601

      # Test
      {responses, only_response, only_response} = FloipPackage.responses(survey, end_timestamp: june_2000_iso8601)

      # Assertions
      assert length(responses) == 1
      assert_same(responses |> Enum.at(0), db_response_1)
    end

    test "return at most 15 responses if size=15" do
      # Setup
      survey = insert_survey()
      respondent_1 = insert_respondent(survey, "1234")
      db_responses = for i <- 1..20 do
        response_minute = String.pad_leading(i |> Integer.to_string, 2, "0")
        insert_response(respondent_1, "Exercises #{i}", "Yes", i, DateTime.from_iso8601("2000-01-01T01:#{response_minute}:03Z") |> elem(1))
      end

      # Test
      {responses, first_response, last_response} = FloipPackage.responses(survey, size: 15)

      # Assertions
      assert length(responses) == 15
      for i <- 0..14 do
        floip_response = responses |> Enum.at(i)
        db_response = db_responses |> Enum.at(i)

        assert_same(floip_response, db_response)

        if (i == 0) do
          assert_same(first_response, db_response)
        end

        if (i == 14) do
          assert_same(last_response, db_response)
        end
      end
    end

    test "return at most 1000 responses if size is not provided" do
      # Setup
      survey = insert_survey()
      respondent_1 = insert_respondent(survey, "1234")
      db_responses = insert_list(2000, :response, respondent: respondent_1)

      # Test
      {responses, first_response, last_response} = FloipPackage.responses(survey)

      # Assertions
      assert length(responses) == 1000
      for i <- 0..999 do
        floip_response = responses |> Enum.at(i)
        db_response = db_responses |> Enum.at(i)
        assert_same(floip_response, db_response)

        if (i == 0) do
          assert_same(first_response, db_response)
        end

        if (i == 999) do
          assert_same(last_response, db_response)
        end
      end
    end

    test "return all responses after an id" do
      survey = insert_survey()
      respondent_1 = insert_respondent(survey, "1234")
      db_responses = for i <- 1..50 do
        response_minute = String.pad_leading(i |> Integer.to_string, 2, "0")
        insert_response(respondent_1, "Exercises #{i}", "Yes", i, DateTime.from_iso8601("2000-01-01T01:#{response_minute}:03Z") |> elem(1))
      end

      # Test
      {responses, first_response, last_response} = FloipPackage.responses(survey, after_cursor: 10)

      # Assertions
      assert length(responses) == 40
      for i <- 0..39 do
        floip_response = responses |> Enum.at(i)
        db_response = db_responses |> Enum.at(i + 10)
        assert_same(floip_response, db_response)

        if (i == 0) do
          assert_same(first_response, db_response)
        end

        if (i == 39) do
          assert_same(last_response, db_response)
        end
      end
    end

    test "return all responses before an id" do
      survey = insert_survey()
      respondent_1 = insert_respondent(survey, "1234")
      db_responses = for i <- 1..50 do
        response_minute = String.pad_leading(i |> Integer.to_string, 2, "0")
        insert_response(respondent_1, "Exercises #{i}", "Yes", i, DateTime.from_iso8601("2000-01-01T01:#{response_minute}:03Z") |> elem(1))
      end

      # Test
      {responses, first_response, last_response} = FloipPackage.responses(survey, before_cursor: 10)

      # Assertions
      assert length(responses) == 9
      for i <- 0..8 do
        floip_response = responses |> Enum.at(i)
        db_response = db_responses |> Enum.at(i)
        assert_same(floip_response, db_response)

        if (i == 0) do
          assert_same(first_response, db_response)
        end

        if (i == 8) do
          assert_same(last_response, db_response)
        end
      end
    end
  end

  describe "uri parsing" do
    test "no query params results in an empty options dict" do
      responses_options = FloipPackage.parse_query_params(%{})
      assert responses_options == %{}
    end

    test "parses all valid query params" do
      query_params = %{
        "filter" => %{
          "end-timestamp" => "2015-11-26 04:34:13Z",
          "max-version" => "2",
          "min-version" => "1",
          "start-timestamp" => "2015-11-26 04:34:13Z"
        },
        "page" => %{
          "afterCursor" => "12",
          "beforeCursor" => "18",
          "size" => "25"
        }
      }

      responses_options = FloipPackage.parse_query_params(query_params)

      {:ok, end_timestamp, _} = DateTime.from_iso8601("2015-11-26 04:34:13Z")
      {:ok, start_timestamp, _} = DateTime.from_iso8601("2015-11-26 04:34:13Z")

      assert responses_options == %{
        end_timestamp: end_timestamp,
        start_timestamp: start_timestamp,
        after_cursor: 12,
        before_cursor: 18,
        size: 25
      }
    end
  end

  describe "query params writing" do
    test "generates query params from complete options" do
      {:ok, end_timestamp, _} = DateTime.from_iso8601("2015-11-26 04:34:13Z")
      {:ok, start_timestamp, _} = DateTime.from_iso8601("2015-11-26 04:34:13Z")

      responses_options = %{
        end_timestamp: end_timestamp,
        start_timestamp: start_timestamp,
        after_cursor: 12,
        before_cursor: 18,
        size: 25
      }

      query_params = FloipPackage.query_params(responses_options)

      iso_start_timestamp = DateTime.to_iso8601(responses_options[:start_timestamp], :extended)
      iso_end_timestamp = DateTime.to_iso8601(responses_options[:end_timestamp], :extended)

      assert query_params == "?filter[start-timestamp]=#{iso_start_timestamp}&filter[end-timestamp]=#{iso_end_timestamp}&page[size]=25&page[afterCursor]=12&page[beforeCursor]=18"
    end

    test "generates query params from empty options" do
      assert FloipPackage.query_params(%{}) == ""
    end
  end

  describe "descriptor" do
    test "works" do
      survey = insert_survey()

      descriptor = FloipPackage.descriptor(survey, "http://gimme.responses")

      assert descriptor == %{
        "data" => %{
          "type" => "packages",
          "id" => FloipPackage.id(survey),
          "attributes" => %{
            "profile" => "flow-results-package",
            "flow-results-specification" => "1.0.0-rc1",
            "created" => FloipPackage.created_at(survey),
            "modified" => FloipPackage.modified_at(survey),
            "id" => FloipPackage.id(survey),
            "title" => FloipPackage.title(survey),
            "name" => FloipPackage.name(survey),
            "resources" => [%{
              "api-data-url" => "http://gimme.responses",
              "encoding" => "utf-8",
              "mediatype" => "application/json",
              "profile" => "data-resource",
              "path" => nil,
              "name" => "#{FloipPackage.name(survey)}-data",
              "schema" => %{
                "fields" => FloipPackage.fields,
                "questions" => FloipPackage.questions(survey)
              }
            }]
          }
        }
      }
    end
  end
end
