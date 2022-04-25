defmodule AskWeb.ErrorView do
  use AskWeb, :view

  def render("404.html", _assigns) do
    "Page not found"
  end

  def render("404.json", _assigns) do
    %{error: "Not found"}
  end

  def render("400.json", _assigns) do
    %{error: "Bad request"}
  end

  def render("500.html", _assigns) do
    "There was an error. Please try again later"
  end

  def render("403.html", _assigns) do
    "Unauthorized"
  end

  def render("403.json", _assigns) do
    %{error: "Unauthorized"}
  end

  def render("error.json", %{error_message: error_message}) do
    %{error: error_message}
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render("500.html", assigns)
  end
end
