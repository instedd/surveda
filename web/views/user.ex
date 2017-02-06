defmodule Ask.UserView do
  use Ask.Web, :view

  def render("user.json", %{user: user}) do
    %{data:
      %{
        email: user.email,
        settings: user.settings
      }
    }
  end

  def render("settings.json", %{settings: settings}) do
    %{data:
      %{
        settings: settings
      }
    }
  end

  def render("error.json", %{changeset: changeset}) do
    %{data:
      %{
        changeset: changeset
      }
    }
  end
end
