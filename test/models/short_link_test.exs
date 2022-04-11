defmodule AskWeb.ShortLinkTest do
  use Ask.DataCase

  alias Ask.ShortLink

  @valid_attrs %{
    hash: "1234",
    name: "123",
    target: "target/path"
  }
  @invalid_attrs %{target: %{}}

  test "changeset with valid attributes" do
    changeset = ShortLink.changeset(%ShortLink{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = ShortLink.changeset(%ShortLink{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "generate_link should automatically generate a 32 char hash" do
    {:ok, link} = ShortLink.generate_link("name", "/target/path")

    assert String.length(link.hash) != 0
    assert link.name == "name"
    assert link.target == "/target/path"
  end

  test "regenerate should generate a new hash" do
    {:ok, link} = ShortLink.generate_link("name", "/target/path")

    {:ok, new_link} = link |> ShortLink.regenerate()

    assert ShortLink |> Repo.all() |> length() == 1
    assert link.hash != new_link.hash
    assert new_link.name == link.name
    assert new_link.id == link.id
    assert new_link.target == link.target
  end
end
