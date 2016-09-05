defmodule Ask.ChannelTest do
  use Ask.ModelCase

  alias Ask.Channel

  @valid_attrs %{name: "name", provider: "foo", settings: %{}, type: "sms", user_id: 999}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Channel.changeset(%Channel{}, @valid_attrs)
    assert changeset.valid?
  end

  test "user must exist" do
    changeset = Channel.changeset(%Channel{}, @valid_attrs)
    assert {:error, changeset} = Repo.insert(changeset)
    assert {:user, {"does not exist", []}} in changeset.errors

    user = insert(:user)
    changeset = Channel.changeset(%Channel{}, %{@valid_attrs | user_id: user.id})
    assert {:ok, _} = Repo.insert(changeset)
  end

  test "changeset with invalid attributes" do
    changeset = Channel.changeset(%Channel{}, @invalid_attrs)
    refute changeset.valid?
  end
end
