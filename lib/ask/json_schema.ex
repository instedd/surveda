defmodule Ask.JsonSchema do
  @moduledoc ~S"""
  A service which validates objects according to types defined in `schema.json`.
  """
  use GenServer

  @server_ref {:global, __MODULE__}

  def server_ref, do: @server_ref

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @server_ref)
    IO.puts "STARTING JSON SCHEMA WORKER"
    IO.inspect @server_ref
  end

  def init(_) do
    schema = File.read!(Application.app_dir(:ask) <> "/priv/schema.json")
             |> Poison.decode!
             |> ExJsonSchema.Schema.resolve
    {:ok, schema}
  end

  def handle_call({:validate, object, type}, _from, schema) do
    errors = get_validation_errors(object, type, schema)
    {:reply, errors, schema}
  end

  def validate(object, type) do
    GenServer.call(@server_ref, {:validate, object, type})
  end

  def errors_to_json(errors) do
    errors |> Enum.map(fn ({msg, _cols}) -> msg end)
  end

  defp get_validation_errors(object, type, schema) do
    type_string = type |> to_string
    type_schema = schema.schema["definitions"][type_string]

    not_a_struct = case object do
      %{__struct__: _} -> Map.from_struct(object)
      _ -> object
    end

    string_keyed_object = ensure_key_strings(not_a_struct)

    ## validate throws a BadMapError on certain kinds of invalid
    ## input; absorb it (TODO fix ExJsonSchema upstream)
    try do
      ExJsonSchema.Validator.validate(schema, type_schema, string_keyed_object)
    rescue
      _ -> [{"Failed validation", []}]
    end
  end

  defp ensure_key_strings(x) do
    cond do
      is_map x ->
        Enum.reduce x, %{}, fn({k,v}, acc) ->
          Map.put acc, to_string(k), ensure_key_strings(v)
        end
      is_list x ->
        Enum.map(x, fn (v) -> ensure_key_strings(v) end)
      true ->
        x
    end
  end
end