defmodule Ask.PageControllerTest do
  use Ask.ConnCase

  test "GET /foo", %{conn: conn} do
    conn = get conn, "/foo"
    assert redirected_to(conn) =~ "/login?redirect=/foo"
  end
end
