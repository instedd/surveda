defmodule Ask.TimezoneControllerTest do
  use Ask.ConnCase

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")
    {:ok, conn: conn, user: user}
  end

  test "returns Timex timezones", %{conn: conn} do
    conn = get conn, timezone_path(conn, :timezones)
    assert json_response(conn, 200)["timezones"] == Timex.timezones
  end

end
