defmodule Ask.Ecto.Type.Steps do
  @moduledoc """
  This Ecto type transforms the steps stored as JSON blob in the database to
  the internal Elixir/Erlang representation (e.g. dispositions are atoms).
  """
  use Ecto.Type

  def type, do: :longtext

  def cast(any) do
    {:ok, transform(any)}
  end

  def cast!(any) do
    transform(any)
  end

  def load(string) when is_binary(string) do
    case Poison.decode(string) do
      {:ok, steps} -> {:ok, transform(steps)}
      any -> any
    end
  end

  def dump(json) do
    Poison.encode(json)
  end

  defp transform(steps) when is_nil(steps), do: nil

  defp transform(steps) do
    steps
    |> Enum.map(fn item ->
      case item["type"] do
        "section" ->
          %{item | "steps" => Enum.map(item["steps"], &transform_one(&1))}

        _ ->
          transform_one(item)
      end
    end)
  end

  defp transform_one(%{"disposition" => disposition} = step) when is_binary(disposition) do
    %{step | "disposition" => String.to_existing_atom(disposition)}
  end

  defp transform_one(step), do: step
end
