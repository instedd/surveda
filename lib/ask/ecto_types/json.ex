defmodule Ask.Ecto.Type.JSON do
  @behaviour Ecto.Type
  def type, do: :text
  def cast(any), do: {:ok, any}
  def load(string) when is_binary(string), do: Poison.decode(string)
  def dump(json), do: Poison.encode(json)
end
