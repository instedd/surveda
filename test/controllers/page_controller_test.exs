defmodule Ask.PageControllerTest do
  use Ask.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert redirected_to(conn) =~ "/landing"
  end
end
