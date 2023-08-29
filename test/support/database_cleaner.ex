defmodule Ask.DatabaseCleaner do
  use GenServer

  @server_ref {:global, __MODULE__}

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @server_ref)
  end

  def init([]) do
    {:ok, %{}}
  end

  def truncate() do
    GenServer.call(@server_ref, :truncate)
  end

  def delete() do
    GenServer.call(@server_ref, :delete)
  end

  def handle_call(:truncate, _, state) do
    {new_state, tables} = get_tables(state)
    tables |> Enum.filter(&changed(&1)) |> truncate()
    {:reply, :ok, new_state}
  end

  def handle_call(:delete, _, state) do
    {new_state, tables} = get_tables(state)
    tables |> Enum.filter(&changed(&1)) |> delete()
    {:reply, :ok, new_state}
  end

  defp changed(table) do
    case sql_query("SELECT EXISTS (SELECT 1 FROM #{table} LIMIT 1)") do
      {:ok, %{rows: [[0]]}} -> false
      {:ok, %{rows: [[_]]}} -> true
    end
  end

  defp truncate([]) do
  end

  defp truncate(tables) do
    disable_integrity(fn ->
      tables |> Enum.each(fn table -> sql_query("TRUNCATE #{table}") end)
    end)
  end

  defp delete([]) do
  end

  defp delete(tables) do
    disable_integrity(fn ->
      tables |> Enum.each(fn table -> sql_query("DELETE FROM #{table}") end)
    end)
  end

  defp disable_integrity(callback) do
    Ask.Repo.checkout(fn ->
      sql_query("SET foreign_key_checks = 0")
      callback.()
      sql_query("SET foreign_key_checks = 1")
    end)
  end

  defp get_tables(state) do
    case state do
      %{tables: tables} ->
        {state, tables}

      _ ->
        {:ok, %{rows: tables}} = sql_query("SHOW tables")

        tables =
          tables
          |> List.flatten()
          |> Enum.reject(fn table -> table == "schema_migrations" end)

        {Map.put(state, :tables, tables), tables}
    end
  end

  defp sql_query(sql) do
    Ask.Repo |> Ecto.Adapters.SQL.query(sql, [], telemetry: false, log: false, query_type: :text)
  end
end
