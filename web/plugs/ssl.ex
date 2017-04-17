defmodule Ask.Plugs.SSL do
  def init(opts) do
    Plug.SSL.init(opts)
  end

  def call(conn, opts) do
    if enabled do
      Plug.SSL.call(conn, opts)
    else
      conn
    end
  end

  defp enabled do
    env_ssl = System.get_env("SSL")
    env_ssl && env_ssl != "0"
  end
end
