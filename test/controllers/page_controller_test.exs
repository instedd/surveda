defmodule Ask.PageControllerTest do
  use Ask.ConnCase

  test "GET /foo", %{conn: conn} do
    conn = get conn, "/foo"
    assert redirected_to(conn) =~ "/sessions/new?redirect=/foo"
  end
end
