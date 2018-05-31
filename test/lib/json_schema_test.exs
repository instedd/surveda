defmodule Ask.StepsValidatorTest do
  use Ask.ModelCase

  alias Ask.JsonSchema

  setup_all do
    GenServer.start_link(JsonSchema, [], name: JsonSchema.server_ref)
    :ok
  end

  defp assert_ok(validation_result), do: assert([] == validation_result, inspect validation_result)
  defp assert_invalid(validation_result, case_desc, thing) do
    assert([] != validation_result, "#{case_desc}: #{thing}")
  end

  defp valid_thing(json_thing, thing_type) do
    json_thing
    |> Poison.decode!
    |> JsonSchema.validate(thing_type)
    |> assert_ok
  end

  defp invalid_thing(json_thing, thing_type, case_desc) do
    json_thing
    |> Poison.decode!
    |> JsonSchema.validate(thing_type)
    |> assert_invalid(case_desc, json_thing)
  end

  # TODO: generate these helpers with macros
  defp valid_questionnaire(json), do: valid_thing(json, :questionnaire)
  defp invalid_questionnaire(json, case_desc), do: invalid_thing(json, :questionnaire, case_desc)

  defp valid_step(json), do: valid_thing(json, :step)
  defp invalid_step(json, case_desc), do: invalid_thing(json, :step, case_desc)

  defp valid_section(json), do: valid_thing(json, :section)
  defp invalid_section(json, case_desc), do: invalid_thing(json, :section, case_desc)

  defp valid_localized_prompt(json), do: valid_thing(json, :localized_prompt)
  defp invalid_localized_prompt(json, case_desc), do: invalid_thing(json, :localized_prompt, case_desc)

  defp valid_prompt(json), do: valid_thing(json, :prompt)
  defp invalid_prompt(json, case_desc), do: invalid_thing(json, :prompt, case_desc)

  defp valid_ivr(json), do: valid_thing(json, :ivr_prompt)
  defp invalid_ivr(json, case_desc), do: invalid_thing(json, :ivr_prompt, case_desc)

  defp valid_choice(json), do: valid_thing(json, :choice)
  defp invalid_choice(json, case_desc), do: invalid_thing(json, :choice, case_desc)

  defp valid_responses(json), do: valid_thing(json, :responses)
  defp invalid_responses(json, case_desc), do: invalid_thing(json, :responses, case_desc)

  defp valid_settings(json), do: valid_thing(json, :settings)
  defp invalid_settings(json, case_desc), do: invalid_thing(json, :settings, case_desc)

  test "questionnaire" do
    ~s({})
    |> invalid_questionnaire("Steps must be mandatory")

    ~s({})
    |> invalid_questionnaire("Settings must be mandatory")

    ~s({"steps": {}, "settings" : {}})
    |> invalid_questionnaire("Questionnaire steps must be an array")

    ~s({"steps": [], "settings" : {}})
    |> valid_questionnaire
  end

  test "step" do
    ~s({
      "type": "numeric",
      "title": "Smoke",
      "prompt": {},
      "store": "Smokes"
    })
    |> invalid_step("Step must have id")

    ~s({
        "id": {},
        "type": "numeric",
        "title": "Smoke",
        "prompt": {},
        "store": "Smokes"
    })
    |> invalid_step("Step id must be a string")

    ~s({
        "id": "fooId",
        "type": "an-unsupported-step-type",
        "title": "Smoke",
        "prompt": {},
        "store": "Smokes"
    })
    |> invalid_step("Step type should be limited to certain values")

    ~s(
    {
      "id": "9616feb6-33c0-4feb-8aa8-84ba9a607103",
      "type": "multiple-choice",
      "prompt": {},
      "store": ""
    })
    |> invalid_step("Step requires title")

    ~s(
    {
      "id": "9616feb6-33c0-4feb-8aa8-84ba9a607103",
      "type": "multiple-choice",
      "title": {},
      "prompt": {},
      "store": ""
    })
    |> invalid_step("Step title must be a string")

    ~s({
      "id": "fooId",
      "type": "numeric",
      "title": "Smoke",
      "store": "Smokes"
    })
    |> invalid_step("Step must have prompt")

    ~s(
    {
      "id": "9616feb6-33c0-4feb-8aa8-84ba9a607103",
      "type": "multiple-choice",
      "title": "Smoke",
      "prompt": {},
      "store": {}
    })
    |> invalid_step("Store must be string")

    ~s(
    {
      "id": "9616feb6-33c0-4feb-8aa8-84ba9a607103",
      "type": "multiple-choice",
      "title": "Smoke",
      "prompt": {},
      "store": "Smokes",
      "choices": {}
    })
    |> invalid_step("Choices must be an array, if present")

    ~s(
    {
      "id": "9616feb6-33c0-4feb-8aa8-84ba9a607103",
      "title": "Language Selection",
      "type": "language-selection",
      "prompt": {},
      "store": "",
      "language_choices": ["en", "fr", "es"]
    })
    |> valid_step

    ~s(
    {
      "id": "9616feb6-33c0-4feb-8aa8-84ba9a607103",
      "title": "Smoke",
      "type": "multiple-choice",
      "prompt": {},
      "store": "Smokes",
      "choices": []
    })
    |> valid_step

    ~s(
    {
      "id": "9616feb6-33c0-4feb-8aa8-84ba9a607103",
      "title": "Explanation",
      "type": "explanation",
      "prompt": {},
      "skip_logic": null
    })
    |> valid_step
  end

  test "section" do
    ~s(
    {
      "id": "9616feb6-33c0-4feb-8aa8-84ba9a607103",
      "title": "First Section",
      "type": "section",
      "randomize": false,
      "steps": []
    })
    |> valid_section

    ~s(
    {
      "id": "9616feb6-33c0-4feb-8aa8-84ba9a607103",
      "title": "First Section",
      "type": "section",
      "randomize": false,
      "steps": [{
        "id": "9616feb6-33c0-4feb-8aa8-84ba9a607103",
        "title": "Smoke",
        "type": "multiple-choice",
        "prompt": {},
        "store": "Smokes",
        "choices": []
      }]
    })
    |> valid_section

    ~s(
    {
      "id": "9616feb6-33c0-4feb-8aa8-84ba9a607103",
      "title": "First Section",
      "type": "section",
      "randomize": false,
      "steps": [{
        "id": "9616feb6-33c0-4feb-8aa8-84ba9a607103",
        "title": "Smoke",
        "type": "multiple-choice",
        "prompt": {},
        "store": "Smokes",
        "choices": []
      },
      {
        "id": "9616feb6-33c0-4feb-8aa8-84ba9a607103",
        "title": "Explanation",
        "type": "explanation",
        "prompt": {},
        "skip_logic": null
      }]
    })
    |> valid_section

    ~s(
    {
      "title": "First Section",
      "type": "section",
      "randomize": false,
      "steps": []
    })
    |> invalid_section("Section must have id")

    ~s(
    {
      "id": "507f7f4f-b037-417f-bf80-e8bfc5d818ff",
      "title": "First Section",
      "type": "not-a-section",
      "randomize": false,
      "steps": []
    })
    |> invalid_section("Section type should be limited to certain values")

    ~s(
    {
      "id": "507f7f4f-b037-417f-bf80-e8bfc5d818ff",
      "title": "First Section",
      "type": "section",
      "steps": []
    })
    |> invalid_section("Section must have randomize")

    ~s(
    {
      "id": "507f7f4f-b037-417f-bf80-e8bfc5d818ff",
      "title": "First Section",
      "type": "section",
      "randomize": false,
      "steps": ["not a step"]
    })
    |> invalid_section("Section must have valid steps")

    ~s(
    {
      "id": "9616feb6-33c0-4feb-8aa8-84ba9a607103",
      "title": "First Section",
      "type": "section",
      "randomize": false,
      "steps": [{
        "id": "9616feb6-33c0-4feb-8aa8-84ba9a607103",
        "title": "Smoke",
        "type": "invalid-step",
        "prompt": {},
        "store": "Smokes",
        "choices": []
      }]
    })
    |> invalid_section("Section must have valid steps")

  end

  test "localized prompt" do
    ~s({
      "en": {
        "foo": "bar"
      }
    }) |> invalid_localized_prompt("Localized prompt must have a lang prompt structure")

    ~s({
      "foobar": {}
    }) |> invalid_localized_prompt("Localized prompt keys must be language indentifiers")

    ~s({
      "123": {}
    }) |> invalid_localized_prompt("Localized prompt keys must be language indentifiers")

    ~s({
      "en": {},
      "fr": {}
    }) |> valid_localized_prompt

     ~s({}) |> valid_localized_prompt
  end

  test "prompt" do
    ~s("") |> invalid_prompt("Prompt must be an object")
    ~s({ "sms": {} }) |> invalid_prompt("Prompt sms must be a string")
    ~s({ "ivr": "" }) |> invalid_prompt("Prompt ivr must be an object")

    ~s({ "sms": "Do you smoke? Reply YES or NO" }) |> valid_prompt

    ~s({
      "ivr": {
        "text": "Do you smoke?",
        "audio_source": "tts"
      }
    })
    |> valid_prompt

    ~s({
      "sms": "Do you smoke? Reply YES or NO",
      "ivr": {
        "text": "Do you smoke?",
        "audio_source": "tts"
      }
    })
    |> valid_prompt

    ~s({"mobileweb": {}}) |> invalid_prompt("Prompt mobile-web must be a string")
    ~s({
      "sms": "Do you smoke? Reply YES or NO",
      "ivr": {
        "text": "Do you smoke?",
        "audio_source": "tts"
      },
      "mobileweb": "Do you smoke?"
    })
    |> valid_prompt
  end

  test "ivr prompt" do
    ~s({
      "text": "foo"
    })
    |> invalid_ivr("IVR Prompt requires audio_source")

    ~s({
      "audio_source": "bar",
      "text": "foo"
    })
    |> invalid_ivr("IVR Prompt requires audio_source to be tts or upload")

    ~s({
      "audio_source": "upload",
      "text": "foo",
      "audio_id": {}
    })
    |> invalid_ivr("IVR Prompt requires audio_id to be a string")

    ~s({
      "audio_source": "tts",
      "text": "How many fingers do you have?"
    })
    |> valid_ivr

    ~s({
      "audio_source": "upload",
      "text": "How many fingers do you have?",
      "audio_id": "3b74aec8-1d5d-4b05-81e3-ab4856062615"
    })
    |> valid_ivr

    ~s({
      "audio_source": "record",
      "text": "How many fingers do you have?",
      "audio_id": "3b74aec8-1d5d-4b05-81e3-ab4856062615"
    })
    |> valid_ivr
  end

  test "choice" do
    ~s({
      "value": "Yes",
      "skip_logic": ""
    })
    |> invalid_choice("Choice requires responses")

    ~s({
      "responses": {},
      "skip_logic": ""
    })
    |> invalid_choice("Choice requires value")

    ~s({
      "value": {},
      "responses": {},
      "skip_logic": ""
    })
    |> invalid_choice("Choice value is a string")

    ~s({
      "value": "Yes",
      "responses": "",
      "skip_logic": ""
    })
    |> invalid_choice("Choice responses is an object")

    ~s({
      "value": "Yes",
      "responses": {}
    })
    |> invalid_choice("Choice requires skip_logic")

    ~s({
      "value": "Yes",
      "responses": {},
      "skip_logic": ""
    })
    |> valid_choice

    ~s({
      "value": "Yes",
      "responses": {},
      "skip_logic": null
    })
    |> valid_choice
  end

  test "responses" do
    ~s({
      "sms": {
        "en": "bar"
      }
    }) |> invalid_responses("Responses must have lang_responses structure")

    ~s({
      "sms": {
        "en" : [],
        "fr" : []
        },
      "ivr": []
    }) |> valid_responses
  end

  test "title" do
    ~s({
      "title": []
    }) |> invalid_settings("title must be an object")

    ~s({
      "title": {
        "en": 1
      }
    }) |> invalid_settings("title values must be strings")

    ~s({
      "title": {
        "foobar": ""
      }
    }) |> invalid_settings("title keys must be language identifiers")

    ~s({
      "title": {
        "en": "foo",
        "es": "bar"
      }
    }) |> valid_settings
  end

  test "survey_already_taken_message" do
    ~s({
      "survey_already_taken_message": []
    }) |> invalid_settings("survey_already_taken_message must be an object")

    ~s({
      "survey_already_taken_message": {
        "en": 1
      }
    }) |> invalid_settings("survey_already_taken_message values must be strings")

    ~s({
      "survey_already_taken_message": {
        "foobar": ""
      }
    }) |> invalid_settings("survey_already_taken_message keys must be language identifiers")

    ~s({
      "survey_already_taken_message": {
        "en": "foo",
        "es": "bar"
      }
    }) |> valid_settings
  end
end
