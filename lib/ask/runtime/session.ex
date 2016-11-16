defmodule Ask.Runtime.Session do
  alias Ask.Runtime.{Flow, Channel, Session}
  alias Ask.Repo
  defstruct [:channel, :fallback, :flow, :respondent, :retries]

  @timeout 5

  def start(questionnaire, respondent, channel, retries \\ [], fallback_channel \\ nil, fallback_retries \\ []) do
    flow = Flow.start(questionnaire, channel.type)
    run_flow(flow, respondent, channel, retries, fallback_channel, fallback_retries)
  end

  defp run_flow(flow, respondent, channel, retries \\ [], fallback_channel \\ nil, fallback_retries \\ []) do
    runtime_channel = Ask.Channel.runtime_channel(channel)
    runtime_channel |> Channel.setup(respondent)

    flow = case runtime_channel |> Channel.can_push_question? do
      true ->
        case flow |> Flow.step do
          {:end, _} -> :end
          {:ok, flow, %{prompts: [prompt]}} ->
            runtime_channel |> Channel.ask(respondent.phone_number, [prompt])
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

  def timeout(session) do
    # Process retries. If there are no more retries, mark session as failed.
    case session.retries do
      [] ->
        case session.fallback do
          # We ran out of retries, and there is no fallback specified
          nil -> :failed
          # If there is a fallback specified, switch session to use it
          _ -> switch_to_fallback(session)
        end
      # Let's try again
      [_ | retries] ->
        runtime_channel = Ask.Channel.runtime_channel(session.channel)

        # Right now this actually means:
        # If we can push a question, it is Nuntium.
        # If we can't push a question, it is Verboice (so we need to schedule
        # a call and wait for the callback to actually execute a step, thus "push").
        case runtime_channel |> Channel.can_push_question? do
          true ->
            {:ok, _flow, %{prompts: prompts}} = Flow.retry(session.flow)
            runtime_channel |> Channel.ask(session.respondent.phone_number, prompts)

          false ->
            runtime_channel |> Channel.setup(session.respondent)
        end
        # The new session will timeout as defined by hd(retries)
        session = %{session | retries: retries}
        {session, current_timeout(session)}
    end
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
        {:ok, %{session | flow: flow}, {:prompt, prompt}, @timeout}
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
end
