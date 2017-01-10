defmodule Ask.UserControllerTest do

  import Ecto.Query

  use Ask.ConnCase
  use Ask.TestHelpers

  alias Ask.{User}

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn, user: user}
  end

  test "updates onboarding screen", %{conn: conn, user: user} do
    attrs = %{onboarding: %{questionnaire: true}}
    conn = put conn, user_path(conn, :update, user), user: attrs
    assert json_response(conn, 200)["data"]["onboarding"]["questionnaire"]
  end

end
