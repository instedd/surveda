defmodule Ask.TranslationTest do
  use Ask.DataCase

  alias Ask.Translation

  @valid_attrs %{
    mode: "some content",
    scope: "prompt",
    source_lang: "some content",
    source_text: "some content",
    target_lang: "some content",
    target_text: "some content"
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Translation.changeset(%Translation{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Translation.changeset(%Translation{}, @invalid_attrs)
    refute changeset.valid?
  end
end
