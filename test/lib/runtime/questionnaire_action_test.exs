defmodule Ask.Runtime.QuestionnaireExportTest do
  use Ask.ModelCase
  alias Ask.Runtime.{QuestionnaireExport, CleanI18n}

  describe "clean_i18n_quiz" do
    test "doesn't change a quiz with no deleted languages" do
      quiz = insert(:questionnaire, languages: ["en"])

      clean = QuestionnaireExport.clean_i18n_quiz(quiz)

      assert clean == quiz
    end

    test "works when quota_completed_steps is nil" do
      quiz = insert(:questionnaire, languages: ["en"], quota_completed_steps: nil)

      clean = QuestionnaireExport.clean_i18n_quiz(quiz)

      assert clean == quiz
    end
  end

  describe "CleanI18n.clean/3" do
    test "cleans a base case" do
      entity = %{"en" => "foo", "es" => "bar"}

      clean = CleanI18n.clean(entity, ["en"], "")

      assert clean == %{"en" => "foo"}
    end

    test "cleans every map element" do
      entity = %{"bar" => %{"en" => "foo", "es" => "bar"}}

      clean = CleanI18n.clean(entity, ["en"], ".[]")

      assert clean == %{"bar" => %{"en" => "foo"}}
    end

    test "cleans every list element" do
      entity = [%{"en" => "foo", "es" => "bar"}]

      clean = CleanI18n.clean(entity, ["en"], ".[]")

      assert clean == [%{"en" => "foo"}]
    end

    test "cleans the requested key of a map" do
      entity = %{"a" => %{"en" => "foo", "es" => "bar"}, "b" => %{"en" => "foo", "es" => "bar"}}

      clean = CleanI18n.clean(entity, ["en"], ".a")

      assert clean == %{"a" => %{"en" => "foo"}, "b" => %{"en" => "foo", "es" => "bar"}}
    end

    test "doesn't crash when the content of the requested key isn't a map" do
      # A real case that was making it crash:
      # entity = [
      #   %{
      #     "choices" => [
      #       %{
      #         "responses" => %{"ivr" => [], "mobileweb" => %{"en" => ""}, "sms" => %{"en" => []}},
      #         "skip_logic" => nil,
      #         "value" => ""
      #       }
      #     ],
      #     "id" => "caad462b-afa4-4c9c-839d-c9e3e7ee4dc1",
      #     "prompt" => %{
      #       "en" => %{
      #         "ivr" => %{"audio_source" => "tts", "text" => ""},
      #         "mobileweb" => "",
      #         "sms" => ""
      #       }
      #     },
      #     "store" => "",
      #     "title" => "",
      #     "type" => "multiple-choice"
      #   }
      # ]
      # clean = CleanI18n.clean(entity, ["en"], ".[].choices.[].responses.[]")

      entity = %{"foo" => "bar"}

      clean = CleanI18n.clean(entity, ["baz"], ".foo")

      assert clean == %{"foo" => "bar"}
    end
  end
end
