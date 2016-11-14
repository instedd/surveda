defmodule Ask.AudioView do
  use Ask.Web, :view

  def render("show.json", %{audio: audio}) do
    %{data: render_one(audio, Ask.AudioView, "audio.json")}
  end

  def render("audio.json", %{audio: audio}) do
    audio
  end
end
