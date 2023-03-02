defmodule Ask.FileInfo do
  @doc """
    Retrieves informations about one or multiple files, using the `file` command
    line tool which is shipped with most linux distributions.
  """
  @spec get_info(Path.t() | [Path.t()]) :: %{Path.t() => String.t()}
  def get_info(names)
  def get_info(name) when is_binary(name), do: get_info([name])

  def get_info(names) when is_list(names) do
    {result, 0} = System.cmd("file", ["--mime-type" | names])

    result
    |> String.split("\n", trim: true)
    |> Stream.filter(&(&1 !== ""))
    |> Stream.map(&String.split(&1, ": ", parts: 2, trim: true))
    |> Stream.map(fn [path, line] -> {path, line} end)
    |> Enum.into(%{})
  end
end
