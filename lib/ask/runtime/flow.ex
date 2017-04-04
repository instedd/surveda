defmodule Ask.Runtime.Flow do
  defstruct current_step: nil, questionnaire: nil, mode: nil, language: nil, retries: 0
  alias Ask.{Repo, Questionnaire}
  alias Ask.Runtime.{Reply, Step}
  alias Ask.Runtime.Flow.Visitor
  alias __MODULE__

  @max_retries 2

  def start(quiz, mode) do
    %Flow{questionnaire: quiz, mode: mode, language: quiz.default_language}
  end

  def step(flow, visitor, reply \\ :answer) do
    flow
    |> accept_reply(reply, visitor)
    |> eval
  end

  def quota_completed(flow, visitor) do
    msg = flow.questionnaire.quota_completed_msg
    if msg do
      visitor = visitor |> Visitor.accept_message(msg, flow.language, "Quota completed")
      {:ok, %Reply{steps: Visitor.close(visitor)}}
    else
      :ok
    end
  end

  def retry(flow, visitor) do
    {flow, %Reply{}, visitor} |> eval
  end

  def dump(flow) do
    %{current_step: flow.current_step, questionnaire_id: flow.questionnaire.id, mode: flow.mode, language: flow.language, retries: flow.retries}
  end

  def load(state) do
    quiz = Repo.get(Questionnaire, state["questionnaire_id"])
    %Flow{questionnaire: quiz, current_step: state["current_step"], mode: state["mode"], language: state["language"], retries: state["retries"]}
  end

  defp next_step_by_skip_logic(flow, step, reply_value) do
    step
    |> Step.skip_logic(reply_value, flow.mode, flow.language)
    |> next_step(flow)
  end

  def next_step(nil, flow), do: flow.current_step + 1
  def next_step("end", flow), do: flow |> end_flow
  def next_step(next_id, flow) do
    next_step_index =
      flow.questionnaire.steps
      |> Enum.find_index(fn istep -> istep["id"] == next_id end)

    if (!next_step_index || flow.current_step > next_step_index) do
      raise "Skip logic: invalid step id."
    else
      next_step_index
    end
  end

  defp advance_current_step(flow, step, reply_value) do
    next_step =
      cond do
        !reply_value && !(step["type"] == "explanation") ->
          flow.current_step + 1
        :else ->
          next_step_by_skip_logic(flow, step, reply_value)
      end

    %{flow | current_step: next_step}
  end

  def end_flow(flow) do
    length(flow.questionnaire.steps)
  end

  defp accept_reply(%Flow{current_step: nil} = flow, :answer, visitor) do
    flow = %{flow | current_step: 0}
    {flow, %Reply{}, visitor}
  end

  defp accept_reply(%Flow{current_step: nil}, _, _) do
    raise "Flow was not expecting any reply"
  end

  defp accept_reply(flow, :answer, visitor) do
    {flow, %Reply{}, visitor}
  end

  defp accept_reply(flow, :no_reply, visitor) do
    if flow.retries >=  @max_retries do
      :failed
    else
      {%{flow | retries: flow.retries + 1}, %Reply{}, visitor}
    end
  end

  defp accept_reply(flow, {:reply, reply}, visitor) do
    if String.downcase(reply) == "stop" do
      :failed
    else
      accept_reply_non_stop(flow, reply, visitor)
    end
  end

  defp accept_reply_non_stop(flow, reply, visitor) do
    step = flow.questionnaire.steps |> Enum.at(flow.current_step)

    reply_value = Step.validate(step, reply, flow.mode, flow.language)

    # Select language to use in next questions
    flow =
      if reply_value != :invalid_answer && step["type"] == "language-selection" do
        %Flow{flow | language: reply_value}
      else
        flow
      end

    case reply_value do
      :invalid_answer ->
        if flow.retries >=  @max_retries do
          :failed
        else
          visitor = visitor |> Visitor.accept_message(flow.questionnaire.error_msg, flow.language, "Error")
          {%{flow | retries: flow.retries + 1}, %Reply{}, visitor}
        end
      nil ->
        flow = flow |> advance_current_step(step, reply_value)
        {%{flow | retries: 0}, %Reply{}, visitor}
      {:refusal, reply_value} ->
        advance_after_reply(flow, step, reply_value, visitor, stores: [])
      reply_value ->
        advance_after_reply(flow, step, reply_value, visitor, stores: %{step["store"] => reply_value})
    end
  end

  defp advance_after_reply(flow, step, reply_value, visitor, stores: stores) do
    flow = flow |> advance_current_step(step, reply_value)
    {%{flow | retries: 0}, %Reply{stores: stores}, visitor}
  end

  def should_update_disposition(old_disposition, new_disposition)
  def should_update_disposition("completed", _), do: false
  def should_update_disposition("ineligible", _), do: false
  def should_update_disposition("partial", "ineligible"), do: false
  def should_update_disposition(_, _), do: true

  # :next_step, :end_survey, {:jump, step_id}, :wait_for_reply
  defp run_step(state, %{"type" => "flag", "disposition" => disposition}) do
    if should_update_disposition(state.disposition, disposition) do
      {:ok, %{state | disposition: disposition}}
    else
      {:ok, state}
    end
  end

  defp run_step(state, %{"type" => "explanation"}) do
    {:ok, state}
  end

  defp run_step(state, _step) do
    {:wait_for_reply, state}
  end

  defp eval(:failed) do
    {:failed, nil, %Reply{}}
  end

  defp eval({flow, state, visitor}) do
    step = flow.questionnaire.steps |> Enum.at(flow.current_step)
    case step do
      nil ->
        {:end, nil, %{state | steps: Visitor.close(visitor)}}
      step ->
        case state |> run_step(step) do
          {:ok, state} ->
            case visitor |> Visitor.accept_step(step, flow.language) do
              {:continue, visitor} ->
                flow = %{flow | current_step: next_step_by_skip_logic(flow, step, nil)}
                eval({flow, state, visitor})
              {:stop, visitor} ->
                {:ok, flow, %{state | steps: Visitor.close(visitor)}}
            end

          {:wait_for_reply, state} ->
            {_, visitor} = visitor |> Visitor.accept_step(step, flow.language)
            {:ok, flow, %{state | steps: Visitor.close(visitor)}}
        end
    end
  end
end

defmodule Ask.Runtime.Flow.Message do
  def reply(response) do
    {:reply, response}
  end

  def no_reply do
    :no_reply
  end

  def answer do
    :answer
  end
end

defprotocol Ask.Runtime.Flow.Visitor do
  # -> {:continue, visitor} | {:stop, visitor}
  def accept_step(visitor, step, lang)
  def accept_message(visitor, message, lang, title)
  def close(visitor)
end

defmodule Ask.Runtime.Flow.TextVisitor do
  alias Ask.Runtime.Flow.TextVisitor
  alias Ask.Runtime.Step
  defstruct reply_steps: [], mode: nil

  def new(mode) do
    %TextVisitor{mode: mode}
  end

  defimpl Ask.Runtime.Flow.Visitor, for: Ask.Runtime.Flow.TextVisitor do
    def accept_step(visitor, step, lang) do
      reply_step = Step.fetch(:reply_step, step, visitor.mode, lang)
      {:continue, add_reply_step(visitor, reply_step)}
    end

    def accept_message(visitor, message, lang, title) do
      reply_step = Step.fetch(:reply_msg, message, visitor.mode, lang, title)
      add_reply_step(visitor, reply_step)
    end

    defp add_reply_step(visitor, nil) do
      visitor
    end

    defp add_reply_step(visitor, reply_step) do
      %{visitor | reply_steps: visitor.reply_steps ++ [reply_step]}
    end

    def close(%TextVisitor{reply_steps: reply_steps}) do
      reply_steps
    end
  end
end

