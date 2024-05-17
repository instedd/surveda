defmodule Ask.Runtime.SurveyCancellerSupervisor do
  alias Ask.Runtime.SurveyCanceller

  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  defp canceller_process_name(survey_id) do
    String.to_atom("SurveyCanceller_#{survey_id}")
  end

  def canceller_pid(survey_id) do
    target_name = canceller_process_name(survey_id)

    case Supervisor.which_children(__MODULE__)
         |> Enum.find(fn {children_name, _, _, _} -> children_name == target_name end) do
      {_, pid, _, _} -> pid
      _ -> nil
    end
  end

  def start_cancelling(survey_id) do
    Supervisor.start_child(__MODULE__, canceller_process_spec(survey_id))
  end

  defp canceller_process_spec(survey_id) do
    %{
      id: canceller_process_name(survey_id),
      start: {SurveyCanceller, :start_link, [survey_id]},
      restart: :transient
    }
  end

  # The SurveyCancellerSupervisor makes sure every cancelling Survey
  # effectively gets cancelled. Upon startup, it checks and starts a
  # SurveyCanceller process for each survey pending of cancellation, and
  # then it also starts new cancellers on demand when a new survey gets
  # cancelled.
  @impl true
  def init(_init_arg) do
    processes_to_start =
      SurveyCanceller.surveys_cancelling()
      |> Enum.map(fn survey_id -> canceller_process_spec(survey_id) end)

    Supervisor.init(processes_to_start, strategy: :one_for_one)
  end
end
