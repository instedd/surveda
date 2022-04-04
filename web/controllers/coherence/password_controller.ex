defmodule Ask.Coherence.PasswordController do
  @moduledoc """
  Handle password recovery actions.

  Controller that handles the recover password feature.

  Actions:

  * new - render the recover password form
  * create - verify user's email address, generate a token, and send the email
  * edit - render the reset password form
  * update - verify password, password confirmation, and update the database
  """
  use Ask.Coherence, :controller
  use Coherence.PasswordControllerBase, schemas: Ask.Coherence.Schemas

  plug :layout_view,
    layout: {Ask.Coherence.LayoutView, :app},
    view: Coherence.PasswordView,
    caller: __MODULE__

  plug :redirect_logged_in when action in [:new, :create, :edit, :update]

  def password_recovery_sent(conn, _) do
    conn |> render("password_recovery_sent.html")
  end
end
