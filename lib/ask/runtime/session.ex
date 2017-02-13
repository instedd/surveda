defmodule Ask.Runtime.Session do
  import Ecto.Query
  import Ecto
  alias Ask.Runtime.{Flow, Channel, Session, Reply}
  alias Ask.{Repo, QuotaBucket, Respondent}
  defstruct [:channel, :fallback, :flow, :respondent, :retries, :token]

  @timeout 10

  def start(questionnaire, respondent, channel, retries \\ [], fallback_channel \\ nil, fallback_retries \\ []) do
    flow = Flow.start(questionnaire, channel.type)
    run_flow(flow, respondent, channel, retries, fallback_channel, fallback_retries)
  end

  defp run_flow(flow, respondent, channel, retries, fallback_channel \\ nil, fallback_retries \\ []) do
    token = Ecto.UUID.generate
    runtime_channel = Ask.Channel.runtime_channel(channel)
    runtime_channel |> Channel.setup(respondent, token)

    {flow, reply} = case runtime_channel |> Channel.can_push_question? do
      true ->
        case flow |> Flow.step do
          {:end, reply} ->
            if Reply.prompts(reply) != [] do
              runtime_channel |> Channel.ask(respondent, token, Reply.prompts(reply))
            end
            {:end, reply}
          {:ok, flow, reply} ->
            runtime_channel |> Channel.ask(respondent, token, Reply.prompts(reply))
            {flow, reply}
        end

      false ->
        {flow, %Reply{}}
    end

    case flow do
      :end ->
        {:end, reply}
      _ ->
        session = %Session{
          channel: channel,
          retries: retries,
          fallback: channel_tuple(fallback_channel, fallback_retries),
          flow: flow,
          respondent: respondent,
          token: token
        }
        {:ok, session, reply, current_timeout(session)}
    end
  end

  defp channel_tuple(nil, _), do: nil
  defp channel_tuple(channel, retries), do: {channel, retries}

  defp clear_token(session) do
    %{session | token: nil}
  end

  # Process retries. If there are no more retries, mark session as failed.
  # We ran out of retries, and there is no fallback specified
  def timeout(session = %Session{retries: [], fallback: nil}) do
    case session.channel |> Ask.Channel.runtime_channel |> Channel.can_push_question? do
      true -> {:stalled, session |> clear_token}
      false -> :failed
    end
  end

  # If there is a fallback specified, switch session to use it
  def timeout(session = %Session{retries: []}), do: switch_to_fallback(session |> clear_token)

  #if we have a last timeout, use it to fallback
  def timeout(session = %Session{retries: [_], fallback: fallback}) when not is_nil(fallback) do
    switch_to_fallback(session |> clear_token)
  end

  # Let's try again
  def timeout(session = %Session{retries: [_ | retries]}) do
    token = Ecto.UUID.generate
    runtime_channel = Ask.Channel.runtime_channel(session.channel)

    # Right now this actually means:
    # If we can push a question, it is Nuntium.
    # If we can't push a question, it is Verboice (so we need to schedule
    # a call and wait for the callback to actually execute a step, thus "push").
    case runtime_channel |> Channel.can_push_question? do
      true ->
        {:ok, _flow, %Reply{prompts: prompts}} = Flow.retry(session.flow)
        runtime_channel |> Channel.ask(session.respondent, token, prompts)

      false ->
        runtime_channel |> Channel.setup(session.respondent, token)
    end
    # The new session will timeout as defined by hd(retries)
    session = %{session | retries: retries, token: token}
    {:ok, session, %Reply{}, current_timeout(session)}
  end

  def channel_failed(%Session{retries: [], fallback: nil, token: token}, token) do
    :failed
  end

  def channel_failed(_session, _token) do
    :ok
  end

  defp switch_to_fallback(session) do
    {fallback_channel, fallback_retries} = session.fallback
    run_flow(%{session.flow | mode: fallback_channel.type}, session.respondent, fallback_channel, fallback_retries)
  end

  def sync_step(session, reply) do
    step_answer = Flow.step(session.flow, reply)

    respondent = session.respondent
    survey = (respondent |> Repo.preload(:survey)).survey

    # Get all quota buckets, if any
    buckets =
      case survey.quota_vars do
        [] -> []
        _ -> Repo.all(from q in QuotaBucket,
               where: q.survey_id == ^survey.id)
      end

    stores =
      case step_answer do
        {:end, %{stores: stores}} -> stores
        {:ok, _, %{stores: stores}} -> stores
      end

    # Store responses, assign respondent to bucket (if any, if there's a match)
    # Since to determine the assigned bucket we need to get all responses,
    # we return them here and reuse them in `falls_in_quota_already_completed`
    # to avoid executing this query twice.
    {respondent, responses} =
      store_responses_and_assign_bucket(respondent, stores, buckets)

    case step_answer do
      {:end, %Reply{prompts: []}} ->
        :end
      {:ok, flow, reply} ->
        case falls_in_quota_already_completed?(buckets, responses) do
          true ->
            msg = quota_completed_msg(session.flow)
            if msg do
              {:rejected, %Reply{prompts: [msg]}}
            else
              :rejected
            end
          false -> {:ok, %{session | flow: flow, respondent: respondent}, reply, @timeout}
        end
      _ ->
        step_answer
    end
  end

  def dump(session) do
    %{
      channel_id: session.channel.id,
      flow: session.flow |> Flow.dump,
      respondent_id: session.respondent.id,
      retries: session.retries,
      fallback_channel_id: fallback_channel_id(session.fallback),
      fallback_retries: fallback_retries(session.fallback),
      token: session.token
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
      fallback: channel_tuple(fallback_channel(state["fallback_channel_id"]), state["fallback_retries"]),
      token: state["token"]
    }
  end

  defp store_responses_and_assign_bucket(respondent, stores, buckets) do
    # Add response to responses
    stores |> Enum.each(fn {field_name, value} ->
      existing_responses = respondent
      |> assoc(:responses)
      |> where([r], r.field_name == ^field_name)
      |> Repo.aggregate(:count, :id)

      if existing_responses == 0 do
        respondent
        |> Ecto.build_assoc(:responses, field_name: field_name, value: value)
        |> Repo.insert
      end
    end)

    # Try to assign a bucket to the respondent
    assign_bucket(respondent, buckets)
  end

  defp current_timeout(%Session{retries: []}) do
    @timeout
  end

  defp current_timeout(%Session{retries: [next_retry | _]}) do
    next_retry
  end

  defp assign_bucket(respondent, []) do
    {respondent, nil}
  end

  defp assign_bucket(respondent, buckets) do
    # Nothing to do if the respondent already has a bucket
    if respondent.quota_bucket_id do
      {respondent, []}
    else
      # Get respondent responses
      responses = (respondent |> Repo.preload(:responses)).responses

      # Convert them to list of {field_name, value}
      responses = responses |> Enum.map(fn response ->
          {response.field_name, response.value}
        end) |> Enum.into([]) |> Enum.sort

      # Check which bucket matches exactly those responses
      buckets = buckets |> Enum.filter(fn bucket ->
        bucket.condition |> Map.to_list |> Enum.all?(fn {key, value} ->
          responses
          |> Enum.filter(fn {response_key, _} -> response_key == key end)
          |> Enum.all?(fn {_, response_value} ->
            response_value |> QuotaBucket.matches_condition?(value)
          end)
        end)
      end)

      respondent =
        case buckets do
          [bucket] ->
            respondent = respondent |> Respondent.changeset(%{quota_bucket_id: bucket.id}) |> Repo.update!
            if respondent.disposition && respondent.disposition == "completed" do
              from(q in QuotaBucket, where: q.id == ^bucket.id) |> Repo.update_all(inc: [count: 1])
            end
            respondent
          _ ->
            respondent
        end

      {respondent, responses}
    end
  end

  defp falls_in_quota_already_completed?(buckets, responses) do
    case buckets do
      # No quotas: not completed
      [] -> false
      _ ->
        # Filter buckets that contain each of the responses
        buckets = responses |> Enum.reduce(buckets, fn(response, buckets) ->
          {response_key, response_value} = response
          buckets |> Enum.filter(fn bucket ->
            # The response must be in the bucket, otherwise we keep the bucket
            if bucket.condition |> Map.keys |> Enum.member?(response_key) do
              bucket.condition |> Map.to_list |> Enum.any?(fn {key, value} ->
                key == response_key && (response_value |> QuotaBucket.matches_condition?(value))
              end)
            else
              true
            end
          end)
        end)

        # The answer is: there it at least one bucket, and all of the buckets are full
        case buckets do
          [] -> false
          _ ->
            buckets |> Enum.all?(fn bucket -> bucket.count >= bucket.quota end)
        end
    end
  end

  defp quota_completed_msg(flow) do
    msg = flow.questionnaire.quota_completed_msg
    if msg do
      (msg |> Map.get(flow.language) |> Map.get(flow.mode)) ||
        (msg |> Map.get(flow.questionnaire.defaultLanguage) |> Map.get(flow.mode))
    else
      nil
    end
  end
end
