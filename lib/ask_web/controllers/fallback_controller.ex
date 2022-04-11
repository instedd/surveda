defmodule AskWeb.FallbackController do
  use Phoenix.Controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(AskWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, :invalid_simulation}),
    do:
      conn
      |> put_status(:bad_request)
      |> put_view(AskWeb.ErrorView)
      |> render(:"400")
end
