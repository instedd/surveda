defmodule Ask.Plugs.SentryContext do
  import User.Helper

  def init(default), do: default

  def call(conn, _) do
    case current_user(conn) do
      nil -> :ok
      user -> Sentry.Context.set_user_context(%{email: user.email})
    end
    conn
  end
end
