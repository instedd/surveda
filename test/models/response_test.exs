defmodule AskWeb.ResponseTest do
  use Ask.DataCase

  alias Ask.Response

  @valid_attrs %{field_name: "some content", value: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Response.changeset(%Response{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Response.changeset(%Response{}, @invalid_attrs)
    refute changeset.valid?
  end
end
