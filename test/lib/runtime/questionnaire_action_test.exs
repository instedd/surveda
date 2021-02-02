defmodule Ask.QuestionnaireExportTest do
  use Ask.ModelCase
  alias Ask.Runtime.QuestionnaireExport

  describe "clean_i18n_entity" do
    test "base case" do
      entity = %{"en" => "foo", "es" => "bar"}

      clean = QuestionnaireExport.clean_i18n_entity(entity, ["en"], "")

      assert clean == %{"en" => "foo"}
    end

    test "move forward" do
      entity = %{"en" => "foo", "es" => "bar"}

      clean = QuestionnaireExport.clean_i18n_entity(entity, ["en"], ".")

      assert clean == %{"en" => "foo"}
    end

    test "clean every map element" do
      entity = %{"bar" => %{"en" => "foo", "es" => "bar"}}

      clean = QuestionnaireExport.clean_i18n_entity(entity, ["en"], "[]")

      assert clean == %{"bar" => %{"en" => "foo"}}
    end

    test "clean every list element" do
      entity = [%{"en" => "foo", "es" => "bar"}]

      clean = QuestionnaireExport.clean_i18n_entity(entity, ["en"], "[]")

      assert clean == [%{"en" => "foo"}]
    end

    test "clean the requested key of a map" do
      entity = %{"a" => %{"en" => "foo", "es" => "bar"}, "b" => %{"en" => "foo", "es" => "bar"}}

      clean = QuestionnaireExport.clean_i18n_entity(entity, ["en"], "a")

      assert clean == %{"a" => %{"en" => "foo"}, "b" => %{"en" => "foo", "es" => "bar"}}
    end
  end

  describe "clean_i18n_quiz" do
    test "doesn't change a quiz with no deleted languages" do
      quiz = insert(:questionnaire, languages: ["en"])

      clean = QuestionnaireExport.clean_i18n_quiz(quiz)

      assert clean == quiz
    end
  end
end
