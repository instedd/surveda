defmodule Ask.Runtime.Session do
  import Ecto.Query
  import Ecto
  alias Ask.{Repo, QuotaBucket, Respondent}
  alias Ask.Runtime.Flow.TextVisitor
  alias Ask.Runtime.{Flow, Channel, Session, Reply, SurveyLogger, ReplyStep, SessionMode, SessionModeProvider, SMSMode, IVRMode, MobileWebMode}
  defstruct [:current_mode, :fallback_mode, :flow, :respondent, :token, :fallback_delay, :channel_state, :count_partial_results]

  @default_fallback_delay 10

  def start(questionnaire, respondent, channel, mode, retries \\ [], fallback_channel \\ nil, fallback_mode \\ nil, fallback_retries \\ [], fallback_delay \\ @default_fallback_delay, count_partial_results \\ false) do
    flow = Flow.start(questionnaire, mode)
    session = %Session{
      current_mode: SessionModeProvider.new(mode, channel, retries),
      fallback_mode: SessionModeProvider.new(fallback_mode, fallback_channel, fallback_retries),
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

  defp mode_start(%Session{flow: flow, respondent: respondent, token: token, current_mode: %SMSMode{channel: channel}} = session) do
    runtime_channel = Ask.Channel.runtime_channel(channel)

    # Is this really necessary?
    Channel.setup(runtime_channel, respondent, token)

    case flow |> Flow.step(session.current_mode |> SessionMode.visitor) do
      {:end, _, reply} ->
        if Reply.prompts(reply) != [] do
          log_prompts(reply, channel, flow.mode, respondent, true)
          runtime_channel |> Channel.ask(respondent, token, reply)
        end
        {:end, reply, respondent}
      {:ok, flow, reply} ->
        log_prompts(reply, channel, flow.mode, respondent)
        runtime_channel |> Channel.ask(respondent, token, reply)
        {:ok, %{session | flow: flow}, reply, current_timeout(session), respondent}
    end
  end

  defp mode_start(%Session{current_mode: %IVRMode{channel: channel}, respondent: respondent, token: token} = session) do
    channel_state = channel
    |> Ask.Channel.runtime_channel
    |> Channel.setup(respondent, token)
    |> handle_setup_response

    session = %{session| channel_state: channel_state}
    {:ok, session, %Reply{}, current_timeout(session), respondent}
  end

  defp mode_start(%Session{flow: flow, respondent: respondent, token: token, current_mode: %MobileWebMode{channel: channel}} = session) do
    runtime_channel = Ask.Channel.runtime_channel(channel)

    # Is this really necessary?
    Channel.setup(runtime_channel, respondent, token)

    reply = mobile_contact_reply(session)

    log_prompts(reply, session.current_mode.channel, flow.mode, session.respondent)
    runtime_channel |> Channel.ask(respondent, token, reply)
    {:ok, %{session | flow: flow}, reply, current_timeout(session), respondent}
  end

  defp mobile_contact_reply(session) do
    %Reply{
      steps: [
        ReplyStep.new(
          mobile_contact_message(session),
          "Contact")
      ]
    }
  end

  defp mobile_contact_message(%Session{flow: flow, respondent: respondent}) do
    msg = flow.questionnaire.settings["mobile_web_sms_message"] || "Please enter"
    prompts = Ask.Runtime.Step.split_by_newlines(msg)

    prompts
    |> Enum.with_index(1)
    |> Enum.map(fn {prompt, index} ->
      if index == length(prompts) do
       "#{prompt} #{url(respondent.id)}"
      else
       prompt
      end
    end)
  end

  defp url(respondent_id) do
    shorten("#{Ask.Endpoint.url}/mobile_survey/#{respondent_id}?token=#{Respondent.token(respondent_id)}")
  end

  defp shorten(url) do
    case Ask.UrlShortener.shorten(url) do
      {:ok, shortened_url} ->
        shortened_url
      {:error, reason} ->
        Ask.Logger.error "Couldn't shorten url. Reason: #{reason}"
        url
      :unavailable ->
        url
    end
  end

  defp current_timeout(%Session{current_mode: %{retries: []}, fallback_delay: fallback_delay}) do
    fallback_delay
  end

  defp current_timeout(%Session{current_mode: %{retries: [next_retry | _]}}) do
    next_retry
  end

  defp run_flow(session) do
    mode_start(%{session | token: Ecto.UUID.generate})
  end

  defp log_prompts(reply, channel, mode, respondent, force \\ false) do
    if force || !(channel |> Ask.Channel.runtime_channel |> Channel.has_delivery_confirmation?) do
      disposition = Reply.disposition(reply) || respondent.disposition
      Enum.each Reply.steps(reply), fn(step) ->
        step.prompts |> Enum.with_index |> Enum.each(fn {_prompt, index} ->
          SurveyLogger.log(
            respondent.survey_id,
            mode,
            respondent.id,
            respondent.hashed_number,
            channel.id,
            disposition,
            :prompt,
            ReplyStep.title_with_index(step, index + 1))
        end)
      end
    end
  end

  defp log_confirmation(title, disposition, channel, mode, respondent) do
    SurveyLogger.log(respondent.survey_id, mode, respondent.id, respondent.hashed_number, channel.id, disposition, :prompt, title)
  end

  defp log_contact(status, channel, mode, respondent, disposition \\ nil) do
    SurveyLogger.log(respondent.survey_id, mode, respondent.id, respondent.hashed_number, channel.id, disposition || respondent.disposition, :contact, status)
  end

  defp log_response(:answer, channel, mode, respondent, disposition) do
    log_contact("Answer", channel, mode, respondent, disposition)
  end

  defp log_response(:no_reply, channel, mode, respondent, disposition) do
    log_contact("Timeout", channel, mode, respondent, disposition)
  end

  defp log_response({:reply, response}, channel, mode, respondent, disposition) do
    SurveyLogger.log(respondent.survey_id, mode, respondent.id, respondent.hashed_number, channel.id, disposition || respondent.disposition, :response, response)
  end

  defp log_response({:reply_with_step_id, response, _step_id}, channel, mode, respondent, disposition) do
    log_response({:reply, response}, channel, mode, respondent, disposition)
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
  def timeout(%{current_mode: %{retries: []}, fallback_mode: nil, respondent: respondent} = session) do
    case session.current_mode do
      %SMSMode{} -> {:stalled, session |> clear_token, respondent}
      %IVRMode{} -> {:failed, respondent}
      %MobileWebMode{} -> {:stalled, session |> clear_token, respondent}
    end
  end

  # If there is a fallback specified, switch session to use it
  def timeout(%{current_mode: %{retries: []}} = session), do: switch_to_fallback(session)

  # Let's try again
  def timeout(%{current_mode: %{retries: [_ | retries]}, channel_state: channel_state, respondent: respondent} = session) do
    runtime_channel = Ask.Channel.runtime_channel(session.current_mode.channel)

    # First, check if there's already a queued message in the channel, to
    # avoid queueing another one before even trying to send the first one.
    if Channel.has_queued_message?(runtime_channel, channel_state) do
      {:ok, session, %Reply{}, current_timeout(session), respondent}
    else
      token = Ecto.UUID.generate
      channel_state =
        case session.current_mode do
          %SMSMode{} ->
            {:ok, _flow, reply} = Flow.retry(session.flow, TextVisitor.new("sms"))
            log_prompts(reply, session.current_mode.channel, session.flow.mode, session.respondent)
            runtime_channel |> Channel.ask(session.respondent, token, reply)
            channel_state

          %IVRMode{} ->
            setup_response = runtime_channel |> Channel.setup(session.respondent, token)
            handle_setup_response(setup_response)

          %MobileWebMode{} ->
            reply = mobile_contact_reply(session)
            log_prompts(reply, session.current_mode.channel, session.flow.mode, session.respondent)
            runtime_channel |> Channel.ask(session.respondent, token, reply)
            channel_state
        end

      # The new session will timeout as defined by hd(retries)
      session = %{session | current_mode: %{session.current_mode | retries: retries}, token: token, channel_state: channel_state}
      {:ok, session, %Reply{}, current_timeout(session), respondent}
    end
  end

  def channel_failed(%Session{current_mode: %{retries: []}, fallback_mode: nil} = session, reason) do
    log_contact(reason, session.current_mode.channel, session.flow.mode, session.respondent)
    :failed
  end

  def channel_failed(session, reason) do
    log_contact(reason, session.current_mode.channel, session.flow.mode, session.respondent)
    :ok
  end

  def delivery_confirm(session, title, current_mode) do
    log_confirmation(title, session.respondent.disposition, current_mode.channel, session.flow.mode, session.respondent)
  end

  defp switch_to_fallback(session) do
    runtime_channel = Ask.Channel.runtime_channel(session.current_mode.channel)

    # Ff there's stil a queued message in the channel, don't fallback yet
    if Channel.has_queued_message?(runtime_channel, session.channel_state) do
      {:ok, session, %Reply{}, current_timeout(session), session.respondent}
    else
      do_switch_to_fallback(session)
    end
  end

  defp do_switch_to_fallback(session) do
    session = session |> clear_token
    run_flow(%Session{
      session |
      current_mode: session.fallback_mode,
      fallback_mode: nil,
      channel_state: nil,
      flow: %{
        session.flow |
        mode: session.fallback_mode |> SessionMode.mode
      }
    })
  end

  def sync_step(session, response) do
    sync_step(session, response, session.current_mode)
  end

  def sync_step(session, response, current_mode) do
    step_answer = Flow.step(session.flow, current_mode |> SessionMode.visitor, response, SessionMode.mode(current_mode))
    respondent = session.respondent

    # Log raw response from user including new disposition
    case step_answer do
      {:end, _, reply} -> log_response(response, current_mode.channel, session.flow.mode, respondent, Reply.disposition(reply))
      {:ok, _flow, reply} -> log_response(response, current_mode.channel, session.flow.mode, respondent, Reply.disposition(reply))
      _ -> :ok
    end

    survey = (respondent |> Repo.preload(:survey)).survey

    # Get all quota buckets, if any
    buckets =
      case survey.quota_vars do
        [] -> []
        _ -> Repo.all(from q in QuotaBucket,
               where: q.survey_id == ^survey.id)
      end

    # Store responses, assign respondent to bucket (if any, if there's a match)
    # Since to determine the assigned bucket we need to get all responses,
    # we return them here and reuse them in `falls_in_quota_already_completed`
    # to avoid executing this query twice.
    {respondent, responses} =
      store_responses_and_assign_bucket(respondent, step_answer, buckets, session)

    session |> handle_step_answer(step_answer, respondent, responses, buckets, current_mode)
  end

  defp handle_step_answer(_, {:end, _, reply}, respondent, _, _, _) do
    {:end, reply, respondent}
  end

  defp handle_step_answer(session, {:ok, flow, reply}, respondent, responses, buckets, current_mode) do
    case falls_in_quota_already_completed?(buckets, responses) do
      true ->
        case Flow.quota_completed(session.flow, current_mode |> SessionMode.visitor) do
        {:ok, reply} ->
          log_prompts(reply, current_mode.channel, flow.mode, respondent, true)
          {:rejected, reply, respondent}
        :ok ->
          {:rejected, respondent}
        end
      false ->
        log_prompts(reply, current_mode.channel, flow.mode, respondent)
        {:ok, %{session | flow: flow, respondent: respondent}, reply, current_timeout(session), respondent}
    end
  end

  defp handle_step_answer(_, {:failed, _, _}, respondent, _, _, _) do
    {:failed, respondent}
  end

  defp handle_step_answer(session, {:stopped, _, reply}, respondent, _, _, current_mode) do
    log_response({:reply, "STOP"}, current_mode.channel, session.flow.mode, respondent, reply.disposition)
    {:stopped, reply, respondent}
  end

  def cancel(session) do
    Ask.Channel.runtime_channel(session.current_mode.channel)
    |> Channel.cancel_message(session.channel_state)
  end

  def dump(session) do
    %{
      current_mode: session.current_mode |> SessionModeProvider.dump,
      fallback_mode: session.fallback_mode |> SessionModeProvider.dump,
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
      current_mode: SessionModeProvider.load(state["current_mode"]),
      fallback_mode: SessionModeProvider.load(state["fallback_mode"]),
      flow: Flow.load(state["flow"]),
      respondent: Repo.get(Ask.Respondent, state["respondent_id"]),
      token: state["token"],
      fallback_delay: state["fallback_delay"],
      channel_state: state["channel_state"],
      count_partial_results: state["count_partial_results"],
    }
  end

  defp store_responses_and_assign_bucket(respondent, {_, _, reply}, buckets, session) do
    # Add response to responses
    Reply.stores(reply) |> Enum.each(fn {field_name, value} ->
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
end
