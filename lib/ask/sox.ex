defmodule Ask.Sox do

  def convert(from_type, from_filename, to_type) do
    try do
      case System.cmd(sox_executable(), ["-V1", "-t", from_type, from_filename, "-e", "signed-integer", "-r", "44100", "-t", to_type, "-c1", "-"]) do
        {output, 0} -> {:ok, output}
        {_, code} -> {:error, code}
      end
    rescue
      e -> {:error, inspect(e)}
    end
  end

  defp sox_executable do
    Application.get_env(:ask, :sox)[:bin] |> System.find_executable
  end

end
