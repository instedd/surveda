defmodule Ask.FFmpeg do
  def convert(from_filename, to_type) do
    try do
      case System.cmd(ffmpeg_executable(), [
             "-hide_banner",
             "-loglevel",
             "error",
             "-i",
             from_filename,
             # output format
             "-f",
             to_type,
             # channels
             "-ac",
             "1",
             # sample rate
             "-ar",
             "44100",
             # constant bitrate (CBR)
             "-b:a",
             "128k",
             "-"
           ]) do
        {output, 0} -> {:ok, output}
        {_, code} -> {:error, code}
      end
    rescue
      e -> {:error, inspect(e)}
    end
  end

  defp ffmpeg_executable do
    Application.get_env(:ask, :ffmpeg)[:bin] |> System.find_executable()
  end
end
