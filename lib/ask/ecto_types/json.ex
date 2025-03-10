defmodule Ask.Ecto.Type.JSON do
  use Ecto.Type
  def type, do: :longtext
  def cast(any), do: {:ok, any}
  def load(string) when is_binary(string), do: Jason.decode(string)
  def dump(json), do: Jason.encode(json)
end
