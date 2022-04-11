defmodule AskWeb.UserControllerTest do
  import Ecto.Query

  alias Ask.User
  use AskWeb.ConnCase
  use Ask.TestHelpers

  setup %{conn: conn} do
    user = insert(:user)

    conn =
      conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn, user: user}
  end

  test "updates settings", %{conn: conn} do
    attrs = %{settings: %{onboarding: %{questionnaire: true}}}
    conn = post conn, update_settings_path(conn, :update_settings), attrs
    assert json_response(conn, 200)["data"]["settings"]["onboarding"]["questionnaire"]
  end

  test "fetches settings", %{conn: conn, user: user} do
    attrs = %{onboarding: %{questionnaire: true}}

    User.changeset(user, %{settings: attrs})
    |> Repo.update!()

    conn = get(conn, settings_path(conn, :settings))
    assert json_response(conn, 200)["data"]["settings"]["onboarding"]["questionnaire"]
  end
end
