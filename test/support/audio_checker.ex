defmodule Ask.AudioChecker do

  def get_audio_format(data, ext) do
    path = "test/tmp/#{Ecto.UUID.generate}.#{ext}"
    File.write(path, data, [:binary])
    case System.cmd("soxi", ["-t", path]) do
      {output, 0} -> output |> String.trim
      {_, _code} -> nil
    end
  end

end
