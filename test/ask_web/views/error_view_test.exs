defmodule AskWeb.ErrorViewTest do
  use AskWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.html" do
    assert render_to_string(AskWeb.ErrorView, "404.html", []) ==
             "Page not found"
  end

  test "render 500.html" do
    assert render_to_string(AskWeb.ErrorView, "500.html", []) ==
             "There was an error. Please try again later"
  end

  test "render any other" do
    assert render_to_string(AskWeb.ErrorView, "505.html", []) ==
             "There was an error. Please try again later"
  end
end
