defmodule Ask.TimezoneController do
  use Ask.Web, :api_controller

  def timezones(conn, _) do
    # only contains the valid (non-deprecated) timezones
    canonical_links = Tzdata.canonical_zone_list() |> Enum.map(fn tz -> {tz, tz} end) |> Map.new()
    # only contains the deprecated timezones with its links to the 'new' timezones
    links = Tzdata.links()

    timezones = Map.merge(canonical_links, links)
    render(conn, "index.json", timezones: timezones)
  end
end
