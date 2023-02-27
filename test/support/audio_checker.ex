defmodule Ask.AudioChecker do
  def get_audio_format(data, ext) do
    path = "test/tmp/#{Ecto.UUID.generate()}.#{ext}"
    File.write(path, data, [:binary])

    %{^path => mime_type} = Ask.FileInfo.get_info(path)
    mime_type
  end
end
