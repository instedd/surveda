defmodule Ask.FolderTest do
  use Ask.ModelCase

  alias Ask.Folder

  @valid_attrs %{}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Folder.changeset(%Folder{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Folder.changeset(%Folder{}, @invalid_attrs)
    refute changeset.valid?
  end
end
