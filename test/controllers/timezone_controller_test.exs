defmodule Ask.TimezoneControllerTest do
  use Ask.ConnCase

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")
    {:ok, conn: conn, user: user}
  end

  describe "the timezones map" do
    test "should link each deprecated timezone with its canonical timezone", %{conn: conn} do
      conn = get conn, timezone_path(conn, :timezones)
      timezones = json_response(conn, 200)["timezones"]

      Tzdata.zone_alias_list()
      |> Enum.each(fn deprecated_tz ->
        assert timezones[deprecated_tz] == Tzdata.links()[deprecated_tz]
      end)
    end

    test "should link each canonical timezone with itself", %{conn: conn} do
      conn = get conn, timezone_path(conn, :timezones)
      timezones = json_response(conn, 200)["timezones"]

      Tzdata.canonical_zone_list()
      |> Enum.each(fn canonical_tz ->
        assert timezones[canonical_tz] == canonical_tz
      end)
    end

    test "should contain all the timezones defined in Timex.timezones", %{conn: conn} do
      conn = get conn, timezone_path(conn, :timezones)
      timezones = json_response(conn, 200)["timezones"]

      assert map_size(timezones) == length(Timex.timezones())
      Timex.timezones() |> Enum.each(fn tz -> assert Map.has_key?(timezones, tz) end)
    end
  end
end
