defmodule AskWeb.CallbackController do
  use AskWeb, :controller

  alias Ask.Channel

  def callback(conn, params = %{"provider" => provider}) do
    channel = Channel.provider(provider)
    channel.callback(conn, params)
  end
end
