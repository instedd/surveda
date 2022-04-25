defmodule AskWeb.IntegrationView do
  use AskWeb, :view

  def render("index.json", %{integrations: integrations}) do
    %{data: render_many(integrations, AskWeb.IntegrationView, "integration.json")}
  end

  def render("show.json", %{integration: integration}) do
    %{data: render_one(integration, AskWeb.IntegrationView, "integration.json")}
  end

  def render("empty.json", %{integration: _integration}) do
    %{data: %{}}
  end

  def render("integration.json", %{integration: integration}) do
    %{
      id: integration.id,
      uri: integration.uri,
      auth_token: integration.auth_token,
      name: integration.name,
      state: integration.state
    }
  end
end
