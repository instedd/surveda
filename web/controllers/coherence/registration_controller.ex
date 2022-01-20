defmodule Ask.Coherence.RegistrationController do
  @moduledoc """
  Handle account registration actions.

  Actions:

  * new - render the register form
  * create - create a new user account
  * edit - edit the user account
  * update - update the user account
  * delete - delete the user account
  """
  use Ask.Coherence, :controller
  use Coherence.RegistrationControllerBase, schemas: Ask.Coherence.Schemas

  @guisso Application.get_env(:ask, :guisso, Guisso)

  plug Coherence.RequireLogin when action in ~w(show edit update delete)a
  plug Coherence.ValidateOption, :registerable
  plug :scrub_params, "registration" when action in [:create, :update]

  plug :layout_view,
    layout: {Ask.Coherence.LayoutView, :app},
    view: Coherence.RegistrationView,
    caller: __MODULE__
  plug :redirect_logged_in when action in [:new, :create]
  plug :guisso_signup when action in [:new]

  defp guisso_signup(conn, _) do
    if @guisso.enabled? do
      conn
      |> @guisso.sign_up("/")
      |> halt()
    else
      conn
    end
  end

  def confirmation_sent(conn, _) do
    conn |> render("confirmation_sent.html")
  end

  def confirmation_expired(conn, _) do
    conn |> render("confirmation_expired.html")
  end
end
