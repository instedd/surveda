defmodule Ask.Coherence.ConfirmationController do
  @moduledoc """
  Handle confirmation actions.

  A single action, `edit`, is required for the confirmation module.

  """
  use Ask.Coherence, :controller
  use Coherence.ConfirmationControllerBase, schemas: Ask.Coherence.Schemas

  plug Coherence.ValidateOption, :confirmable

  plug :layout_view,
    layout: {Ask.Coherence.LayoutView, :app},
    view: Coherence.ConfirmationView,
    caller: __MODULE__

  plug(:redirect_logged_in when action in [:new])
end
