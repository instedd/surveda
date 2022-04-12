defmodule AskWeb do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use AskWeb, :controller
      use AskWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: AskWeb

      alias Ask.Repo
      import Ecto
      import Ecto.Query
      import Ecto.Changeset

      import AskWeb.Router.Helpers
      import AskWeb.Gettext

      import User.Helper
      import CSV.Helper
      import Pagination.Helper
      import Changeset.Helper

      # Sets HTTP headers to cache the response for 1 year, as recommended by
      # [RFC 2616](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.21).
      def put_cache_headers(conn) do
        conn
        |> put_resp_header("cache-control", "public, max-age=31556926, immutable")
      end
    end
  end

  def api_controller do
    quote do
      use AskWeb, :controller
      plug Guisso.OAuth
      plug AskWeb.Plugs.ApiAuthenticated
      plug AskWeb.Plugs.SentryContext
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/ask_web/templates", namespace: AskWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import AskWeb.Router.Helpers
      import AskWeb.ErrorHelpers
      import AskWeb.Gettext
      import User.Helper
    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      alias Ask.Repo
      import Ecto
      import Ecto.Query
      import AskWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
