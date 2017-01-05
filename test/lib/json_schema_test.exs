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

  defp valid_prompt(json), do: valid_thing(json, :prompt)
  defp invalid_prompt(json, case_desc), do: invalid_thing(json, :prompt, case_desc)

  defp valid_lang_prompt(json), do: valid_thing(json, :lang_prompt)
  defp invalid_lang_prompt(json, case_desc), do: invalid_thing(json, :lang_prompt, case_desc)

  defp valid_ivr(json), do: valid_thing(json, :ivr)
  defp invalid_ivr(json, case_desc), do: invalid_thing(json, :ivr, case_desc)

  defp valid_choice(json), do: valid_thing(json, :choice)
  defp invalid_choice(json, case_desc), do: invalid_thing(json, :choice, case_desc)

  defp valid_responses(json), do: valid_thing(json, :responses)
  defp invalid_responses(json, case_desc), do: invalid_thing(json, :responses, case_desc)

  test "questionnaire" do
    ~s({})
    |> invalid_questionnaire("Steps must be mandatory")

    ~s({"steps": {}})
    |> invalid_questionnaire("Questionnaire steps must be an array")

    ~s({"steps": []})
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
      "choices": ["en", "fr", "es"]
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
  end

  test "prompt" do
    ~s({
      "en": {
        "foo": "bar"
      }
    }) |> invalid_prompt("Prompt must have a lang prompt structure")

    ~s({
      "en": {},
      "fr": {}
    }) |> valid_prompt

     ~s({}) |> valid_prompt
  end

  test "lang prompt" do
    ~s("") |> invalid_lang_prompt("Prompt must be an object")
    ~s({ "sms": {} }) |> invalid_lang_prompt("Prompt sms must be a string")
    ~s({ "ivr": "" }) |> invalid_lang_prompt("Prompt ivr must be an object")

    ~s({ "sms": "Do you smoke? Reply YES or NO" }) |> valid_lang_prompt

    ~s({
      "ivr": {
        "text": "Do you smoke?",
        "audio_source": "tts"
      }
    })
    |> valid_lang_prompt

    ~s({
      "sms": "Do you smoke? Reply YES or NO",
      "ivr": {
        "text": "Do you smoke?",
        "audio_source": "tts"
      }
    })
    |> valid_lang_prompt
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
end
