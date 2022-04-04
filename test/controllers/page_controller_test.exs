defmodule Ask.PageControllerTest do
  use Ask.ConnCase

  test "GET /foo", %{conn: conn} do
    conn = get(conn, "/foo")
    assert redirected_to(conn) =~ "/sessions/new?#{URI.encode_query(redirect: "/foo")}"
  end

  test "GET /foo/bar/baz", %{conn: conn} do
    conn = get(conn, "/foo/bar/baz")
    assert redirected_to(conn) =~ "/sessions/new?#{URI.encode_query(redirect: "/foo/bar/baz")}"
  end

  test "GET /foo with parameters", %{conn: conn} do
    conn = get(conn, "/foo?param1=33&param2=54")

    assert redirected_to(conn) =~
             "/sessions/new?#{URI.encode_query(redirect: "/foo?param1=33&param2=54")}"
  end
end
