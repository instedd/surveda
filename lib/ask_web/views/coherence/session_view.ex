defmodule AskWeb.Coherence.SessionView do
  use AskWeb.Coherence, :view

  def render("session.json", %{user: user}) do
    %{
      user: %{
        id: user.id,
        name: user.name,
        email: user.email
      }
    }
  end

  def render("error.json", %{error: error}) do
    %{
      error: error
    }
  end

  def render("error.json", _opts) do
    %{
      error: "Invalid credentials"
    }
  end
end
