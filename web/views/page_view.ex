defmodule Ask.PageView do
  use Ask.Web, :view

  def config_intercom(_conn) do
    Ask.Intercom.config_intercom()
  end
end
