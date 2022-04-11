defmodule AskWeb.PageView do
  use AskWeb, :view

  def config_intercom(_conn) do
    Ask.Intercom.config_intercom()
  end
end
