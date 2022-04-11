defmodule AskWeb.Coherence.LayoutView do
  use AskWeb.Coherence, :view

  def config_intercom(_conn) do
    Ask.Intercom.config_intercom()
  end
end
