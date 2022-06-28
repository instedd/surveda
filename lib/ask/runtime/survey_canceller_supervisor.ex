defmodule Ask.Runtime.SurveyCancellerSupervisor do
  alias Ask.Runtime.SurveyCancellerSupervisor
  alias Ask.SurveyCanceller
  use Supervisor

  def start_link() do
    SurveyCancellerSupervisor.start_link([])
  end

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    survey_canceller = SurveyCanceller.start_cancelling(nil)

    case survey_canceller do
      :ignore ->
        :ignore

      %SurveyCanceller{processes: processes, consumers_pids: _} ->
        Supervisor.start_link(processes, strategy: :rest_for_one)
    end
  end
end
