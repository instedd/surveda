defmodule Ask.Web do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use Ask.Web, :controller
      use Ask.Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      # Avoid microseconds. Mysql doesn't support them.
      # See [usec in datetime](https://hexdocs.pm/ecto_sql/Ecto.Adapters.MyXQL.html#module-usec-in-datetime)
      @timestamps_opts [type: :utc_datetime, usec: false]
    end
  end

  def controller do
    quote do
      use Phoenix.Controller

      alias Ask.Repo
      import Ecto
      import Ecto.Query
      import Ecto.Changeset

      import Ask.Router.Helpers
      import Ask.Gettext

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
      use Ask.Web, :controller
      plug Guisso.OAuth
      plug Ask.Plugs.ApiAuthenticated
      plug Ask.Plugs.SentryContext
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "web/templates"

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import Ask.Router.Helpers
      import Ask.ErrorHelpers
      import Ask.Gettext
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
      import Ask.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
