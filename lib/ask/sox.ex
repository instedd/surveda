defmodule Ask.Sox do
  def convert(from_filename, to_type) do
    try do
      case System.cmd(sox_executable(), [
             "-V1",
             "--magic",
             from_filename,
             "--encoding", "signed-integer",
             "--channels", "1",
             "--rate", "44100",
             "--type", to_type,
             "-"
           ]) do
        {output, 0} -> {:ok, output}
        {_, code} -> {:error, code}
      end
    rescue
      e -> {:error, inspect(e)}
    end
  end

  defp sox_executable do
    Application.get_env(:ask, :sox)[:bin] |> System.find_executable()
  end
end
