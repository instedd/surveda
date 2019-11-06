defmodule Ask.RespondentsCancellerProducer do
  use Ecto.Schema
  import Ecto.Query

  alias Ask.Respondent
  alias Ask.Survey
  alias Ask.Repo

  use GenStage

  def start_link(initial) do
    GenStage.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def init(survey_id) when not is_nil(survey_id)do
    state = %{survey_ids: [survey_id], last_updated_respondent_id: 0}
    {:producer, state}
  end

  def init(survey_id) when is_nil(survey_id)do
    query = from(
      s in Survey,
      where: (s.state == "cancelling"),
      select: s.id
    )
    survey_ids = query
                 |> Repo.all

    case survey_ids do
      [] -> GenStage.stop(self(), :normal)
      _-> :ok
    end
    state = %{survey_ids: survey_ids, last_updated_respondent_id: 0}

    {:producer, state}
  end

  def handle_demand(_demand, state) do
    respondents = get_respondents_for_update(state)
    handle_respondents(respondents, state)
  end

  def handle_respondents(respondents, state) when length(respondents) > 0 do
    last_id = List.last(respondents).id
    new_state = %{survey_ids: state.survey_ids, last_updated_respondent_id: last_id}
    {:noreply, respondents, new_state}
  end


  def handle_respondents(respondents, state) when length(respondents) == 0 do
    state.survey_ids
    |> Enum.each(
         fn survey_id ->
           survey = Repo.get(Survey, survey_id)
           survey
           |> Survey.changeset(%{"state": "terminated", "exit_code": 1, "exit_message": "Cancelled by user"})
           |> Repo.update!
         end
       )

    {:stop, :normal, state}
  end

  def get_respondents_for_update(state) do
    query = from(
      r in Respondent,
      where: (
        ((r.state == "active") or (r.state == "stalled")) and (r.survey_id in ^state.survey_ids) and (
          r.id > ^state.last_updated_respondent_id)),
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
  alias Ask.RespondentsCancellerProducer
  alias Ask.Respondent
  alias Ask.Repo
  alias Ask.Runtime.Session
  use GenStage, restart: :transient

  def start_link(_initial) do
    GenStage.start_link(__MODULE__, :state, name: __MODULE__)
  end

  def init(state) do
    {:consumer, state, subscribe_to: [{RespondentsCancellerProducer, max_demand: 50, min_demand: 1}]}
  end

  def handle_events(respondents, _from, state) do
    sessions = respondents
              |> Enum.map(&(&1.session))
              |> Enum.reject(&is_nil/1)

    sessions
    |> Enum.each(
         fn session ->
           session
           |> Session.load
           |> Session.cancel
         end
       )

    respondents
    |> Enum.each(
         fn respondent ->
           respondent
           |> Respondent.changeset(%{state: "cancelled", session: nil, timeout_at: nil})
           |> Repo.update!
         end
       )

    {:noreply, [], state}
  end
end


