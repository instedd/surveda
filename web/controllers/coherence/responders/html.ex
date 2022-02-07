defmodule Coherence.Responders.Html do
  use Responders.Html

  # Failed to login because the account hasn't been confirmed, yet. We redirect
  # to the confirmation page, so the user may send and receive a new
  # confirmation email.
  def session_create_error(conn, %{new_bindings: _new_bindings, error: _error}) do
    conn |> redirect_to(:confirmation_create, {})
  end

  def session_create_error(conn, %{new_bindings: new_bindings}) do
    conn
    |> put_status(401)
    |> render(:new, new_bindings)
  end

  # User registration was successful. We must transform all pending invitations
  # into proper memberships, so the user can immediately access all the
  # projects she has been invited to.
  def registration_create_success(conn, %{params: params, user: user}) do
    Ask.ProjectMembership.accept_pending_invitations(user)
    conn |> redirect_to(:session_create, params)
  end
end
