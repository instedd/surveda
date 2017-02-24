defmodule Ask.Runtime.Flow do
  defstruct current_step: nil, questionnaire: nil, mode: nil, language: nil, retries: 0
  alias Ask.{Repo, Questionnaire}
  alias Ask.Runtime.{Reply, Step}
  alias __MODULE__

  @max_retries 2

  def start(quiz, mode) do
    %Flow{questionnaire: quiz, mode: mode, language: quiz.default_language}
  end

  def step(flow, reply \\ :answer) do
    flow
    |> accept_reply(reply)
    |> eval
  end

  def retry(flow) do
    {flow, %Reply{}} |> eval
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
    |> Step.skip_logic(reply_value)
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

  defp accept_reply(%Flow{current_step: nil} = flow, :answer) do
    flow = %{flow | current_step: 0}
    {flow, %Reply{}}
  end

  defp accept_reply(%Flow{current_step: nil}, _) do
    raise "Flow was not expecting any reply"
  end

  defp accept_reply(flow, :answer) do
    {flow, %Reply{}}
  end

  defp accept_reply(flow, :no_reply) do
    if flow.retries >=  @max_retries do
      {%{flow | current_step: flow |> end_flow}, %Reply{}}
    else
      {%{flow | retries: flow.retries + 1}, %Reply{}}
    end
  end

  defp accept_reply(flow, {:reply, reply}) do
    step = flow.questionnaire.steps |> Enum.at(flow.current_step)

    reply_value = Step.validate(step, reply, flow.mode, flow.language, flow.questionnaire.default_language)

    # Select language to use in next questions
    flow =
      if step["type"] == "language-selection" do
        %Flow{flow | language: reply_value}
      else
        flow
      end

    case reply_value do
      :invalid_answer ->
        if flow.retries >=  @max_retries do
          {%{flow | current_step: flow |> end_flow}, %Reply{}}
        else
          {%{flow | retries: flow.retries + 1}, %Reply{prompts: Step.fetch(:error_msg, flow.questionnaire.error_msg, flow.mode, flow.language, flow.questionnaire.default_language)}}
        end
      nil ->
        flow = flow |> advance_current_step(step, reply_value)
        {%{flow | retries: 0}, %Reply{}}
      reply_value ->
        flow = flow |> advance_current_step(step, reply_value)
        {%{flow | retries: 0}, %Reply{stores: %{step["store"] => reply_value}}}
    end
  end

  defp eval({flow, state}) do
    step = flow.questionnaire.steps |> Enum.at(flow.current_step)
    case step do
      nil ->
        {:end, state}
      step ->
        case step["type"] do
          "explanation" ->
            add_explanation_step_prompt(flow, state)
          "flag" ->
            add_disposition_to_next_step(flow, state, step)
          _ ->
            {:ok, flow, %{state | prompts: (state.prompts || []) ++ Step.fetch(:prompt, step, flow.mode, flow.language, flow.questionnaire.default_language)}}
        end
    end
  end

  defp add_explanation_step_prompt(flow, state) do
    step = flow.questionnaire.steps |> Enum.at(flow.current_step)
    state = %{state | prompts: (state.prompts || []) ++ Step.fetch(:prompt, step, flow.mode, flow.language, flow.questionnaire.default_language)}
    flow = %{flow | current_step: next_step_by_skip_logic(flow, step, nil)}
    eval({flow, state})
  end

  defp add_disposition_to_next_step(flow, state, step) do
    state = %{state | disposition: step["disposition"]}
    flow = %{flow | current_step: next_step_by_skip_logic(flow, step, nil)}
    eval({flow, state})
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
