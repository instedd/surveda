defmodule AskWeb.Coherence.ConfirmationController do
  @moduledoc """
  Handle confirmation actions.

  A single action, `edit`, is required for the confirmation module.

  """
  use AskWeb.Coherence, :controller
  use Coherence.ConfirmationControllerBase, schemas: Ask.Coherence.Schemas

  plug Coherence.ValidateOption, :confirmable

  plug :layout_view,
    layout: {AskWeb.Coherence.LayoutView, :app},
    view: Coherence.ConfirmationView,
    caller: __MODULE__

  plug(:redirect_logged_in when action in [:new])
end
