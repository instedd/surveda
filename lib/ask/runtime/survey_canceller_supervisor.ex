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

  @impl true
  def init(_init_arg) do
    processes_to_start =
      SurveyCanceller.surveys_cancelling()
      |> Enum.map(fn survey_id ->
        process_name = String.to_atom("SurveyCanceller_#{survey_id}")

        %{
          id: process_name,
          start: {SurveyCanceller, :start_link, [survey_id]},
          restart: :transient
        }
      end)

    Supervisor.init(processes_to_start, strategy: :one_for_one)
  end
end
