defmodule Ask.RespondentsCancellerProducer do
  use Ecto.Schema
  import Ecto.Query
  alias Ask.{Respondent, Survey, Repo, ActivityLog, Project}
  alias Ecto.Multi
  use GenStage

  def start_link(initial) do
    GenStage.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def init(survey_id) when not is_nil(survey_id) do
    state = %{survey_ids: [survey_id], last_updated_respondent_id: 0}
    {:producer, state}
  end

  def init(survey_id) when is_nil(survey_id) do
    query =
      from(
        s in Survey,
        where: s.state == :cancelling,
        select: s.id
      )

    survey_ids =
      query
      |> Repo.all()

    case survey_ids do
      [] ->
        :ignore

      _ ->
        state = %{survey_ids: survey_ids, last_updated_respondent_id: 0}
        {:producer, state}
    end
  end

  def handle_demand(_demand, state) do
    respondent_ids = get_respondents_for_update(state)
    handle_respondents(respondent_ids, state)
  end

  def handle_respondents(respondent_ids, state) when length(respondent_ids) > 0 do
    last_id = List.last(respondent_ids)
    new_state = %{survey_ids: state.survey_ids, last_updated_respondent_id: last_id}
    {:noreply, respondent_ids, new_state}
  end

  def handle_respondents(respondent_ids, state) when length(respondent_ids) == 0 do
    state.survey_ids
    |> Enum.each(fn survey_id ->
      survey = Repo.get(Survey, survey_id)
      project = Repo.get!(Project, survey.project_id)

      changeset =
        Survey.changeset(survey, %{
          state: "terminated",
          exit_code: 1,
          exit_message: "Cancelled by user"
        })

      Multi.new()
      |> Multi.update(:survey, changeset)
      |> Multi.insert(:log, ActivityLog.completed_cancel(project, nil, survey))
      |> Repo.transaction()
    end)

    {:stop, :normal, state}
  end

  def get_respondents_for_update(state) do
    query =
      from(
        r in Respondent,
        select: r.id,
        where:
          r.state == :active and r.survey_id in ^state.survey_ids and
            r.id > ^state.last_updated_respondent_id,
        limit: 100,
        order_by: [
          asc: r.id
        ]
      )

    Repo.all(query)
  end
end

defmodule Ask.RespondentsCancellerConsumer do
  use Ecto.Schema
  alias Ask.{RespondentsCancellerProducer, Respondent, Repo}
  alias Ask.Runtime.Session
  use GenStage, restart: :transient

  def start_link(_initial) do
    GenStage.start_link(__MODULE__, :state, name: __MODULE__)
  end

  def init(producer_pid) do
    {:consumer, :state, subscribe_to: [{producer_pid, max_demand: 50, min_demand: 1}]}
  end

  def handle_events(respondent_ids, _from, state) do
    respondent_ids
    |> Enum.each(fn respondent_id -> Respondent.with_lock(respondent_id, &cancel_respondent/1) end)

    {:noreply, [], state}
  end

  defp cancel_respondent(respondent) do
    if respondent.session != nil do
      respondent.session
      |> Session.load()
      |> Session.cancel()
    end

    respondent
    |> Respondent.changeset(%{state: "cancelled", session: nil, timeout_at: nil})
    |> Repo.update!()
  end
end

defmodule Ask.SurveyCanceller do
  use Ecto.Schema
  use GenServer
  import Ecto.Query

  alias Ask.{
    ActivityLog,
    Logger,
    Project,
    Repo,
    Respondent,
    RespondentsCancellerConsumer,
    RespondentsCancellerProducer,
    Survey
  }

  alias Ask.Runtime.Session
  alias Ecto.Multi

  def start_link(survey_id) do
    GenServer.start_link(__MODULE__, survey_id)
  end

  @impl true
  def init(survey_id) do
    :timer.send_after(1000, :cancel)
    Logger.info("Starting canceller for survey #{survey_id}")
    {:ok, survey_id}
  end

  defp respondents_to_cancel(survey_id) do
    Repo.all(
      from(
        r in Respondent,
        select: r.id,
        where: r.state == :active and r.survey_id == ^survey_id,
        limit: 100
      )
    )
  end

  defp cancel_survey(survey_id) do
    survey = Repo.get(Survey, survey_id)
    project = Repo.get!(Project, survey.project_id)

    changeset =
      Survey.changeset(survey, %{
        state: "terminated",
        exit_code: 1,
        exit_message: "Cancelled by user"
      })

    Multi.new()
    |> Multi.update(:survey, changeset)
    |> Multi.insert(:log, ActivityLog.completed_cancel(project, nil, survey))
    |> Repo.transaction()
  end

  defp cancel_respondent(respondent) do
    if respondent.session != nil do
      respondent.session
      |> Session.load()
      |> Session.cancel()
    end

    respondent
    |> Respondent.changeset(%{state: "cancelled", session: nil, timeout_at: nil})
    |> Repo.update!()
  end

  defp cancel_respondents(respondent_ids, survey_id) do
    Logger.debug("Cancelling #{Enum.count(respondent_ids)} respondents for survey #{survey_id}")

    respondent_ids
    |> Enum.each(fn respondent_id -> Respondent.with_lock(respondent_id, &cancel_respondent/1) end)
  end

  @impl true
  def handle_info(:cancel, survey_id) do
    Logger.info("Canceller handling :cancel (id: #{survey_id})")

    case respondents_to_cancel(survey_id) do
      [] ->
        cancel_survey(survey_id)
        Logger.info("Finished cancelling survey #{survey_id}")
        {:stop, :normal, nil}

      respondent_ids ->
        cancel_respondents(respondent_ids, survey_id)
        :timer.send_after(1000, :cancel)
        {:noreply, survey_id}
    end
  end

  @impl true
  def handle_info(message, survey_id) do
    Logger.info("Canceller handling #{message} (id: #{survey_id})")
    {:noreply, survey_id}
  end

  @default_number_consumers 3

  defstruct [:processes, :consumers_pids]

  defp start_producer(survey_id) do
    producer_name = String.to_atom("RespondentsCancellerProducer_#{Ecto.UUID.generate()}")
    GenStage.start_link(RespondentsCancellerProducer, survey_id, name: producer_name)
  end

  defp start_consumers(number_consumers, producer_pid) do
    names =
      Enum.map(1..number_consumers, fn _ ->
        String.to_atom("RespondentsCancellerConsumer_#{Ecto.UUID.generate()}")
      end)

    names
    |> Enum.map(fn name ->
      GenStage.start_link(RespondentsCancellerConsumer, producer_pid, name: name)
    end)
  end

  def surveys_cancelling() do
    from(
      s in Survey,
      where: s.state == :cancelling,
      select: s.id
    )
    |> Repo.all()
  end

  def start_cancelling(survey_id, number_consumers \\ @default_number_consumers) do
    # returns a SurveyCanceller where
    # * processes is the list of processes started (two-element tuples)
    # * consumers_pids are only the pids of the consumers
    Logger.info("Start cancelling survey (id: #{survey_id})")
    producer = start_producer(survey_id)

    case producer do
      {:ok, producer_pid} ->
        consumers = start_consumers(number_consumers, producer_pid)
        consumers_pids = consumers |> Enum.map(fn {_, pid} -> pid end)
        %Ask.SurveyCanceller{processes: [producer | consumers], consumers_pids: consumers_pids}

      :ignore ->
        :ignore
    end
  end
end
