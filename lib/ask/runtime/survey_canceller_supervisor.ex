defmodule Ask.Runtime.SurveyCancellerSupervisor do
  alias Ask.Runtime.SurveyCancellerSupervisor

  alias Ask.{
    SurveyCanceller,
    RespondentsCancellerProducer,
    RespondentsCancellerConsumer
  }

  use Supervisor

  @default_number_consumers 3

  def start_link() do
    SurveyCancellerSupervisor.start_link([])
  end

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  defp consumer_name(survey_id, index_number) do
    String.to_atom("RespondentsCancellerConsumer_#{survey_id}_#{index_number}")
  end

  defp processes_to_cancel_surveys(survey_ids) do
    survey_ids
    |> Enum.flat_map(fn survey_id ->
      producer_name = String.to_atom("RespondentsCancellerProducer_#{survey_id}")

      [
        %{id: producer_name, start: {RespondentsCancellerProducer, :start_link, [survey_id]}},
        # FIXME: parametrizable amount
        %{
          id: consumer_name(survey_id, 1),
          start: {RespondentsCancellerConsumer, :start_link, [producer_name]}
        },
        %{
          id: consumer_name(survey_id, 2),
          start: {RespondentsCancellerConsumer, :start_link, [producer_name]}
        },
        %{
          id: consumer_name(survey_id, 3),
          start: {RespondentsCancellerConsumer, :start_link, [producer_name]}
        }
      ]
    end)
  end

  @impl true
  def init(_init_arg) do
    surveys_to_cancel = SurveyCanceller.surveys_cancelling()
    processes_to_start = processes_to_cancel_surveys(surveys_to_cancel)
    Supervisor.init(processes_to_start, strategy: :rest_for_one)
  end
end
