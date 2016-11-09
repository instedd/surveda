defmodule Ask.TimezoneView do
  use Ask.Web, :view

  def render("index.json", %{timezones: timezones}) do
    %{
      timezones: timezones
    }
  end
end
