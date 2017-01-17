defmodule Ask.StaticServingTest do
  use Ask.ConnCase

  setup %{conn: conn} do  
    {:ok, conn: conn}
  end

  describe "get static file" do
    test "when it requests an existing file it works it returns 200", %{conn: conn} do
      conn = get conn, "/favicon.ico"
      assert conn.status == 200
    end

    test "when it requests a non-existent file inside a folder that contains statics it returns a 404", %{conn: conn} do
      conn = get conn, "/fonts/NobodyWouldNameAFontLikeThis.tff"
      assert conn.status == 404
    end

    test "when it requests anything outside static folders it continues", %{conn: conn} do
      conn = get conn, "/foo/bar"
      # In this case we expect a 302 because we're trying to get a non-existing path 
      # without an authenticated user. It has to redirect to login.
      assert conn.status == 302
    end
  end
end
