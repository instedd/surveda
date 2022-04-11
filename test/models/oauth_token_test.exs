defmodule AskWeb.OAuthTokenTest do
  use Ask.DataCase

  alias Ask.OAuthToken

  @valid_attrs %{access_token: %{}, provider: "some content", user_id: 1}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = OAuthToken.changeset(%OAuthToken{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = OAuthToken.changeset(%OAuthToken{}, @invalid_attrs)
    refute changeset.valid?
  end
end
