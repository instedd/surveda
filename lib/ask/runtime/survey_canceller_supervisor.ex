defmodule Ask.Runtime.SurveyCancellerSupervisor do
  alias Ask.Runtime.SurveyCancellerSupervisor

  alias Ask.{
    SurveyCanceller,
    RespondentsCancellerProducer,
    RespondentsCancellerConsumer
  }

  use Supervisor

  def start_link() do
    SurveyCancellerSupervisor.start_link([])
  end

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_cancelling(survey_id) do
    Supervisor.start_child(__MODULE__, canceller_process_spec(survey_id))
  end

  defp canceller_process_spec(survey_id) do
    process_name = String.to_atom("SurveyCanceller_#{survey_id}")

    %{
      id: process_name,
      start: {SurveyCanceller, :start_link, [survey_id]},
      restart: :transient
    }
  end

  @impl true
  def init(_init_arg) do
    processes_to_start =
      SurveyCanceller.surveys_cancelling()
      |> Enum.map(fn survey_id -> canceller_process_spec(survey_id) end)

    Supervisor.init(processes_to_start, strategy: :one_for_one)
  end
end
