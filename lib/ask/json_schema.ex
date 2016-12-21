defmodule Ask.JsonSchema do
  @moduledoc ~S"""
  A service which validates objects according to types defined in `schema.json`.
  """
  use GenServer
  require Logger
  defmodule State do
    defstruct [:schema_path, :schema_mtime, :schema]
  end

  @server_ref {:global, __MODULE__}

  def server_ref, do: @server_ref

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @server_ref)
  end

  def init([]), do: init(["schema.json"])
  def init([schema_path]) do
    schema_path = Application.app_dir(:ask) <> "/priv/" <> schema_path
    schema_mtime = File.stat!(schema_path).mtime
    schema = load_schema(schema_path)

    if Mix.env == :dev do
      :timer.send_interval(:timer.seconds(1), :reload)
    end

    {:ok, %State{schema_path: schema_path, schema_mtime: schema_mtime, schema: schema}}
  end

  def handle_call({:validate, object, type}, _from, state) do
    errors = get_validation_errors(object, type, state.schema)
    {:reply, errors, state}
  end

  def handle_info(:reload, state) do
    mtime = File.stat!(state.schema_path).mtime

    state = if mtime > state.schema_mtime do
      try do
        schema = load_schema(state.schema_path)
        Logger.info "Schema reloaded!"
        %{state | schema_mtime: mtime, schema: schema}
      rescue
        e ->
          Logger.info "Error during schema reloading: #{inspect e}"
          %{state | schema_mtime: mtime}
      end
    else
      state
    end

    {:noreply, state}
  end

  def validate(object, type, server \\ @server_ref) do
    GenServer.call(server, {:validate, object, type})
  end

  def errors_to_json(errors) do
    errors |> Enum.map(fn ({msg, cols}) -> "#{msg}: #{inspect cols}" end)
  end

  defp load_schema(schema_path) do
    File.read!(schema_path)
    |> Poison.decode!
    |> ExJsonSchema.Schema.resolve
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
