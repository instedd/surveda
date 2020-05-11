defmodule Ask.FallbackController do
  use Phoenix.Controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(Ask.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, :not_implemented}), do: call(conn, {:error, :not_found})

end