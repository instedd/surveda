defmodule Coherence.LayoutView do
  use Ask.Coherence.Web, :view

  def config_intercom(_conn) do
    Ask.Intercom.config_intercom()
  end
end
