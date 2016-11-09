defmodule Ask.TimezoneController do
  use Ask.Web, :api_controller

  def timezones(conn, _) do
    timezones = Timex.timezones
    render(conn, "index.json", timezones: timezones)
  end
end
