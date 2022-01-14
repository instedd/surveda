defmodule Coherence.Redirects do
  @moduledoc """
  Define controller action redirection functions.

  This module contains default redirect functions for each of the controller
  actions that perform redirects. By using this Module you get the following
  functions:

  * session_create/2
  * session_delete/2
  * password_create/2
  * password_update/2,
  * unlock_create_not_locked/2
  * unlock_create_invalid/2
  * unlock_create/2
  * unlock_edit_not_locked/2
  * unlock_edit/2
  * unlock_edit_invalid/2
  * registration_create/2
  * invitation_create/2
  * confirmation_create/2
  * confirmation_edit_invalid/2
  * confirmation_edit_expired/2
  * confirmation_edit/2
  * confirmation_edit_error/2

  You can override any of the functions to customize the redirect path. Each
  function is passed the `conn` and `params` arguments from the controller.

  ## Examples

      import Ask.Router.Helpers

      # override the log out action back to the log in page
      def session_delete(conn, _), do: redirect(conn, to: session_path(conn, :new))

      # redirect the user to the login page after registering
      def registration_create(conn, _), do: redirect(conn, to: session_path(conn, :new))

      # disable the user_return_to feature on login
      def session_create(conn, _), do: redirect(conn, to: landing_path(conn, :index))

  """
  use Redirects
  # Uncomment the import below if adding overrides
  import Ask.Router.Helpers

  def session_create(conn, %{"session" => %{"redirect" => ""}}), do: redirect(conn, to: "/")
  def session_create(conn, %{"session" => %{"redirect" => path}}) do
    redirect(conn, to: path)
  end
  def session_create(conn, _), do: redirect(conn, to: "/")

  def session_delete(conn, params) do
    if Guisso.enabled? do
      redirect_url = "#{url(conn)}#{logged_out_url(conn)}"
      conn |> Guisso.sign_out(redirect_url)
    else
      super(conn, params)
    end
  end

  def registration_create(conn, _), do: redirect(conn, to: registration_path(conn, :confirmation_sent))
  def confirmation_create(conn, _), do: redirect(conn, to: registration_path(conn, :confirmation_sent))
  def confirmation_edit(conn, _), do: redirect(conn, to: session_path(conn, :new))
  def confirmation_edit_expired(conn, _), do: redirect(conn, to: registration_path(conn, :confirmation_expired))
  def password_create(conn, _), do: redirect(conn, to: password_path(conn, :password_recovery_sent))
  def password_update(conn, _), do: redirect(conn, to: session_path(conn, :new))
end
