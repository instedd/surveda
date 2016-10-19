defmodule Ask.ProjectTest do
  use Ask.ModelCase

  alias Ask.Project

  @valid_attrs %{name: "some content"}

  test "changeset with valid attributes" do
    changeset = Project.changeset(%Project{}, @valid_attrs)
    assert changeset.valid?
  end
end
