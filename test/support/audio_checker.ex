defmodule Ask.AudioChecker do
  def get_audio_format(data) do
    path = "test/tmp/#{Ecto.UUID.generate()}.audio"
    File.write(path, data, [:binary])

    try do
      %{^path => mime_type} = Ask.FileInfo.get_info(path)
      mime_type
    after
      File.rm(path)
    end
  end
end
