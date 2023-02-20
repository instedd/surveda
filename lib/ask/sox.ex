defmodule Ask.Sox do
  def convert(from_filename, to_type) do
    try do
      case System.cmd(sox_executable(), [
             "-V1",
             "--magic",
             from_filename,
             "--encoding",
             "signed-integer",
             "--channels",
             "1",
             "--rate",
             "44100",
             "--type",
             to_type,
             "-"
           ]) do
        {output, 0} -> {:ok, output}
        {_, code} -> {:error, code}
      end
    rescue
      e -> {:error, inspect(e)}
    end
  end

  # Sox doesn't support AAC directly, we must first transcode to PCM using
  # ffmpeg then transcode to MP3 using Sox. Maybe we could transcode to MP3
  # directly from ffmpeg but I couldn't find the arguments to set encoding,
  # channels or rate in ffmpeg.
  def convert_aac(from_filename, to_type) do
    wav_filename = tmp_filename(from_filename, ".wav")
    try do
      case System.cmd(ffmpeg_executable(), [
             "-hide_banner",
             "-loglevel", "error",
             "-i", from_filename,
             wav_filename,
           ]) do
        {_, 0} -> convert(wav_filename, to_type)
        {_, code} -> {:error, code}
      end
    rescue
      e -> {:error, inspect(e)}
    after
      File.rm(wav_filename)
    end
  end

  defp tmp_filename(filename, extname) do
    name = Path.basename(filename, Path.extname(filename))
    Path.join(System.tmp_dir(), "surveda-convert-aac-#{name}#{extname}")
  end

  defp sox_executable do
    Application.get_env(:ask, :sox)[:bin] |> System.find_executable()
  end

  defp ffmpeg_executable do
    Application.get_env(:ask, :ffmpeg)[:bin] |> System.find_executable()
  end
end
