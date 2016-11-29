defmodule Ask.Runtime.Session do
  import Ecto.Query
  alias Ask.Runtime.{Flow, Channel, Session}
  alias Ask.{Repo, QuotaBucket}
  defstruct [:channel, :fallback, :flow, :respondent, :retries]

  @timeout 10

  def start(questionnaire, respondent, channel, retries \\ [], fallback_channel \\ nil, fallback_retries \\ []) do
    flow = Flow.start(questionnaire, channel.type)
    run_flow(flow, respondent, channel, retries, fallback_channel, fallback_retries)
  end

  defp run_flow(flow, respondent, channel, retries, fallback_channel \\ nil, fallback_retries \\ []) do
    runtime_channel = Ask.Channel.runtime_channel(channel)
    runtime_channel |> Channel.setup(respondent)

    flow = case runtime_channel |> Channel.can_push_question? do
      true ->
        case flow |> Flow.step do
          {:end, _} -> :end
          {:ok, flow, %{prompts: [prompt]}} ->
            runtime_channel |> Channel.ask(respondent.sanitized_phone_number, [prompt])
            flow
        end

      false ->
        flow
    end

    case flow do
      :end -> :end
      _ ->
        session = %Session{
          channel: channel,
          retries: retries,
          fallback: channel_tuple(fallback_channel, fallback_retries),
          flow: flow,
          respondent: respondent
        }
        {session, current_timeout(session)}
    end
  end

  defp channel_tuple(nil, _), do: nil
  defp channel_tuple(channel, retries), do: {channel, retries}

  # Process retries. If there are no more retries, mark session as failed.
  # We ran out of retries, and there is no fallback specified
  def timeout(session = %Session{retries: [], fallback: nil}) do
    case session.channel |> Ask.Channel.runtime_channel |> Channel.can_push_question? do
      true -> {:stalled, session}
      false -> :failed
    end
  end

  # If there is a fallback specified, switch session to use it
  def timeout(session = %Session{retries: []}), do: switch_to_fallback(session)

  #if we have a last timeout, use it to fallback
  def timeout(session = %Session{retries: [_], fallback: fallback}) when not is_nil(fallback) do
    switch_to_fallback(session)
  end

  # Let's try again
  def timeout(session = %Session{retries: [_ | retries]}) do
    runtime_channel = Ask.Channel.runtime_channel(session.channel)

    # Right now this actually means:
    # If we can push a question, it is Nuntium.
    # If we can't push a question, it is Verboice (so we need to schedule
    # a call and wait for the callback to actually execute a step, thus "push").
    case runtime_channel |> Channel.can_push_question? do
      true ->
        {:ok, _flow, %{prompts: prompts}} = Flow.retry(session.flow)
        runtime_channel |> Channel.ask(session.respondent.sanitized_phone_number, prompts)

      false ->
        runtime_channel |> Channel.setup(session.respondent)
    end
    # The new session will timeout as defined by hd(retries)
    session = %{session | retries: retries}
    {session, current_timeout(session)}
  end

  defp switch_to_fallback(session) do
    {fallback_channel, fallback_retries} = session.fallback
    run_flow(%{session.flow | mode: fallback_channel.type}, session.respondent, fallback_channel, fallback_retries)
  end

  def sync_step(session, reply) do
    case Flow.step(session.flow, reply) do
      {:end, %{stores: stores}} ->
        store_responses(session.respondent, stores)
        :end

      {:ok, flow, %{prompts: [prompt], stores: stores}} ->
        store_responses(session.respondent, stores)
        case falls_in_quota_already_completed?(session.respondent) do
          true -> :end
          false -> {:ok, %{session | flow: flow}, {:prompt, prompt}, @timeout}
        end
    end
  end

  def dump(session) do
    %{
      channel_id: session.channel.id,
      flow: session.flow |> Flow.dump,
      respondent_id: session.respondent.id,
      retries: session.retries,
      fallback_channel_id: fallback_channel_id(session.fallback),
      fallback_retries: fallback_retries(session.fallback)
    }
  end

  defp fallback_channel(nil), do: nil
  defp fallback_channel(id) do
    Repo.get(Ask.Channel, id)
  end

  defp fallback_channel_id(nil), do: nil
  defp fallback_channel_id({channel, _}), do: channel.id

  defp fallback_retries(nil), do: nil
  defp fallback_retries({_, retries}), do: retries

  def load(state) do
    %Session{
      channel: Repo.get(Ask.Channel, state["channel_id"]),
      flow: Flow.load(state["flow"]),
      respondent: Repo.get(Ask.Respondent, state["respondent_id"]),
      retries: state["retries"],
      fallback: channel_tuple(fallback_channel(state["fallback_channel_id"]), state["fallback_retries"])
    }
  end

  defp store_responses(respondent, stores) do
    stores |> Enum.each(fn {field_name, value} ->
      respondent
      |> Ecto.build_assoc(:responses, field_name: field_name, value: value)
      |> Ask.Repo.insert
    end)
  end

  defp current_timeout(%Session{retries: []}) do
    @timeout
  end

  defp current_timeout(%Session{retries: [next_retry | _]}) do
    next_retry
  end

  defp falls_in_quota_already_completed?(respondent) do
    survey_id = respondent.survey_id

    # Get all quotas
    buckets = Repo.all(from q in QuotaBucket,
          where: q.survey_id == ^survey_id)

    case buckets do
      # No quotas: not completed
      [] -> false
      _ ->
        # Get respondent responses
        responses = (respondent |> Repo.preload(:responses)).responses

        # Convert them to list of {field_name, value}
        responses = responses |> Enum.map(fn response ->
            {response.field_name, response.value}
          end) |> Enum.into([])

        # Get non-completed buckets
        buckets = buckets |> Enum.filter(fn bucket  ->
            bucket.count < bucket.quota
          end)

        # Convert them to a list of list of {key, value} using the condition
        buckets = buckets |> Enum.map(fn bucket -> bucket.condition |> Map.to_list end)

        # Filter buckets that contain each of the responses
        buckets = responses |> Enum.reduce(buckets, fn(response, buckets) ->
          buckets |> Enum.filter(fn bucket -> bucket |> Enum.member?(response) end)
        end)

        # If no non-completed buckets are left, it means that
        # the responses are already covered by current quotas
        buckets |> Enum.empty?
    end
  end
end
