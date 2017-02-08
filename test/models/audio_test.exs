defmodule Ask.AudioTest do
  use Ask.ModelCase

  alias Ask.Audio

  test "mime type" do
    assert "audio/mpeg" = %Audio{filename: "foo.mp3"} |> Audio.mime_type
    assert "audio/wav" = %Audio{filename: "foo.wav"} |> Audio.mime_type
    assert "application/octet-stream" = %Audio{filename: "foo.bar"} |> Audio.mime_type
  end
end
