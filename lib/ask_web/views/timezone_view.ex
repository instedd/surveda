defmodule AskWeb.TimezoneView do
  use AskWeb, :view

  def render("index.json", %{timezones: timezones}) do
    %{
      timezones: timezones
    }
  end
end
