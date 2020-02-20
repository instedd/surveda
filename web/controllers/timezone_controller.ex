defmodule Ask.TimezoneController do
  use Ask.Web, :api_controller

  def timezones(conn, _) do
    canonical_links = Tzdata.canonical_zone_list() # only contains the valid (non-deprecated) timezones
                      |> Enum.map(fn tz -> {tz, tz} end) |> Map.new
    links = Tzdata.links() # only contains the deprecated timezones with its links to the 'new' timezones

    timezones = Map.merge(canonical_links, links)
    render(conn, "index.json", timezones: timezones)
  end
end
