defmodule Ask.UserView do
  use Ask.Web, :view

  def render("user.json", %{user: user}) do
    %{data:
      %{
        email: user.email,
        onboarding: user.onboarding
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
