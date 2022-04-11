defmodule AskWeb.AudioView do
  use AskWeb, :view

  def render("show.json", %{audio: audio}) do
    %{data: render_one(audio, AskWeb.AudioView, "audio.json")}
  end

  def render("audio.json", %{audio: audio}) do
    audio
  end
end
