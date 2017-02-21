defmodule Ask.Runtime.Session do
  import Ecto.Query
  import Ecto
  alias Ask.Runtime.{Flow, Channel, Session, Reply}
  alias Ask.{Repo, QuotaBucket, Respondent}
  defstruct [:current_mode, :fallback_mode, :flow, :respondent, :token, :fallback_delay, :channel_state, :count_partial_results]

  defmodule ModeInfo do
    defstruct [:mode, :channel, :retries]

    def new(nil, _retries), do: nil
    def new(channel, retries) when not is_nil(channel) and is_list(retries) do
      %ModeInfo{mode: channel.type, channel: channel, retries: retries}
    end

    def dump(nil), do: nil
    def dump(%ModeInfo{mode: mode, channel: channel, retries: retries}) do
      %{
        mode: mode,
        channel_id: channel.id,
        retries: retries
      }
    end

    def load(nil), do: nil
    def load(mode_dump) do
      %ModeInfo{
        mode: mode_dump["mode"],
        channel: Ask.Channel |> Repo.get(mode_dump["channel_id"]),
        retries: mode_dump["retries"]
      }
    end
  end

  @default_fallback_delay 10

  def start(questionnaire, respondent, channel, retries \\ [], fallback_channel \\ nil, fallback_retries \\ [], fallback_delay \\ @default_fallback_delay, count_partial_results \\ false) do
    flow = Flow.start(questionnaire, channel.type)
    session = %Session{
      current_mode: ModeInfo.new(channel, retries),
      fallback_mode: ModeInfo.new(fallback_channel, fallback_retries),
      flow: flow,
      respondent: respondent,
      fallback_delay: fallback_delay,
      count_partial_results: count_partial_results
    }
    run_flow(session)
  end

  def default_fallback_delay do
    @default_fallback_delay
  end

  defp run_flow(session = %Session{flow: flow, respondent: respondent, current_mode: %ModeInfo{channel: channel}}) do
    token = Ecto.UUID.generate
    runtime_channel = Ask.Channel.runtime_channel(channel)

    setup_response = runtime_channel |> Channel.setup(respondent, token)
    channel_state = handle_setup_response(setup_response)

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
        session = %{session | flow: flow, token: token, channel_state: channel_state}
        {:ok, session, reply, current_timeout(session)}
    end
  end

  defp handle_setup_response(setup_response) do
    case setup_response do
      {:ok, new_state} ->
        new_state
      _ ->
        # TODO: handle Channel.setup errors
        nil
    end
  end

  defp clear_token(session) do
    %{session | token: nil}
  end

  # Process retries. If there are no more retries, mark session as failed.
  # We ran out of retries, and there is no fallback specified
  def timeout(session = %Session{current_mode: %{retries: []}, fallback_mode: nil}) do
    case session.current_mode.channel |> Ask.Channel.runtime_channel |> Channel.can_push_question? do
      true -> {:stalled, session |> clear_token}
      false -> :failed
    end
  end

  # If there is a fallback specified, switch session to use it
  def timeout(session = %Session{current_mode: %{retries: []}}), do: switch_to_fallback(session |> clear_token)

  #if we have a last timeout, use it to fallback
  # TODO: this should use fallback_delay
  def timeout(session = %Session{current_mode: %{retries: [_]}, fallback_mode: fallback}) when not is_nil(fallback) do
    switch_to_fallback(session |> clear_token)
  end

  # Let's try again
  def timeout(session = %Session{current_mode: %{retries: [_ | retries]}, channel_state: channel_state}) do
    runtime_channel = Ask.Channel.runtime_channel(session.current_mode.channel)

    # First, check if there's already a queued message in the channel, to
    # avoid queueing another one before even trying to send the first one.
    if Channel.has_queued_message?(runtime_channel, channel_state) do
      {:ok, session, %Reply{}, current_timeout(session)}
    else
      token = Ecto.UUID.generate

      # Right now this actually means:
      # If we can push a question, it is Nuntium.
      # If we can't push a question, it is Verboice (so we need to schedule
      # a call and wait for the callback to actually execute a step, thus "push").

      channel_state =
        case runtime_channel |> Channel.can_push_question? do
          true ->
            {:ok, _flow, %Reply{prompts: prompts}} = Flow.retry(session.flow)
            runtime_channel |> Channel.ask(session.respondent, token, prompts)
            channel_state

          false ->
            setup_response = runtime_channel |> Channel.setup(session.respondent, token)
            handle_setup_response(setup_response)
        end

      # The new session will timeout as defined by hd(retries)
      session = %{session | current_mode: %{session.current_mode | retries: retries}, token: token, channel_state: channel_state}
      {:ok, session, %Reply{}, current_timeout(session)}
    end
  end

  def channel_failed(%Session{current_mode: %{retries: []}, fallback_mode: nil, token: token}, token) do
    :failed
  end

  def channel_failed(_session, _token) do
    :ok
  end

  defp switch_to_fallback(session) do
    run_flow(%{
      session |
      current_mode: session.fallback_mode,
      fallback_mode: nil,
      channel_state: nil,
      flow: %{
        session.flow |
        mode: session.fallback_mode.mode
      }
    })
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
      store_responses_and_assign_bucket(respondent, stores, buckets, session)

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
          false ->
            {:ok, %{session | flow: flow, respondent: respondent}, reply, session.fallback_delay}
        end
      _ ->
        step_answer
    end
  end

  def dump(session) do
    %{
      current_mode: session.current_mode |> ModeInfo.dump,
      fallback_mode: session.fallback_mode |> ModeInfo.dump,
      flow: session.flow |> Flow.dump,
      respondent_id: session.respondent.id,
      token: session.token,
      fallback_delay: session.fallback_delay,
      channel_state: session.channel_state,
      count_partial_results: session.count_partial_results
    }
  end

  def load(state) do
    %Session{
      current_mode: ModeInfo.load(state["current_mode"]),
      fallback_mode: ModeInfo.load(state["fallback_mode"]),
      flow: Flow.load(state["flow"]),
      respondent: Repo.get(Ask.Respondent, state["respondent_id"]),
      token: state["token"],
      fallback_delay: state["fallback_delay"],
      channel_state: state["channel_state"],
      count_partial_results: state["count_partial_results"],
    }
  end

  defp store_responses_and_assign_bucket(respondent, stores, buckets, session) do
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
    assign_bucket(respondent, buckets, session)
  end

  defp current_timeout(%Session{current_mode: %{retries: []}, fallback_delay: fallback_delay}) do
    fallback_delay
  end

  defp current_timeout(%Session{current_mode: %{retries: [next_retry | _]}}) do
    next_retry
  end

  defp assign_bucket(respondent, [], _session) do
    {respondent, nil}
  end

  defp assign_bucket(respondent, buckets, session) do
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
            if (session.count_partial_results && respondent.disposition && respondent.disposition == "partial") || (respondent.disposition && respondent.disposition == "completed") do
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
