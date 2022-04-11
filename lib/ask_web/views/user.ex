defmodule AskWeb.UserView do
  use AskWeb, :view

  def render("settings.json", %{settings: settings}) do
    %{
      data: %{
        settings: settings
      }
    }
  end

  def render("error.json", %{changeset: changeset}) do
    %{
      data: %{
        changeset: changeset
      }
    }
  end
end
