defmodule Ask.Runtime.QuestionnaireSimulatorStore do
  use GenServer
  alias Ask.{Logger, SystemTime}

  @ttl_minutes Ask.ConfigHelper.get_config(__MODULE__, :simulation_ttl, &String.to_integer/1)

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    Logger.info("QuestionnaireSimulator started with simulation_ttl: #{@ttl_minutes}")
    :timer.send_after(1000, :clean)
    {:ok, %{}}
  end

  defp ttl_expired?({_key, {ts, _}}) do
    ttl_minutes_ago = Timex.shift(SystemTime.time.now, minutes: -@ttl_minutes)
    Timex.before?(ts, ttl_minutes_ago)
  end

  def handle_info(:clean, state) do
    old_keys = state |> Enum.filter(&ttl_expired?/1) |> Enum.map(fn {key, _} -> key end)
    new_state = old_keys |> Enum.reduce(state, fn key, accum -> Map.delete(accum, key) end)
    if(old_keys != []) do Logger.debug("Cleaning old simulations. Respondent ids: #{inspect old_keys}") end

    :timer.send_after(:timer.minutes(1), :clean)
    {:noreply, new_state}
  end

  def handle_call({:get_status, respondent_id}, _from, state) do
    status = state |> Map.get(respondent_id)
    {:reply, if status do elem(status, 1) else nil end, state}
  end

  def handle_call({:add_status, respondent_id, status}, _from, state) do
    new_state = state |> Map.put(respondent_id, {SystemTime.time.now, status})
    {:reply, status, new_state}
  end

  # Only useful for tests
  def handle_call(:clean, _from, state) do
    {:noreply, new_state} = handle_info(:clean, state)
    {:reply, :ok, new_state}
  end

  def add_respondent_simulation(respondent_id, simulation_status) do
    GenServer.call(__MODULE__, {:add_status, respondent_id, simulation_status})
  end

  def get_respondent_simulation(respondent_id) do
    GenServer.call(__MODULE__, {:get_status, respondent_id})
  end
end