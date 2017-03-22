defmodule Ask.Runtime.Flow do
  defstruct current_step: nil, questionnaire: nil, mode: nil, language: nil, retries: 0
  alias Ask.{Repo, Questionnaire}
  alias Ask.Runtime.Reply
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

  defp is_numeric(str) do
    case Float.parse(str) do
      {num, ""} -> num
      {_num, _r} -> false               # _r : remainder_of_bianry
      :error     -> false
    end
  end

  defp is_in_numeric_range(step, value) do
    min_value = step["min_value"]
    max_value = step["max_value"]
    !((min_value && value < min_value) || (max_value && value > max_value))
  end

  defp is_refusal_option(%{"refusal" => refusal = %{"enabled" => true}}, flow, reply) do
    fetch(:response, flow, refusal)
    |> Enum.any?(fn r -> (r |> clean_string) == reply end)
  end

  defp is_refusal_option(_, _, _) do
    false
  end

  defp next_step_by_skip_logic(flow, step, reply_value) do
    skip_logic =
      case step["type"] do
        "numeric" ->
          if is_refusal_option(step, flow, reply_value) do
            step["refusal"]["skip_logic"]
          else
            value = String.to_integer(reply_value)
            step["ranges"]
            |> Enum.find_value(nil, fn (range) ->
              if (range["from"] == nil || range["from"] <= value) && (range["to"]
                == nil || range["to"] >= value), do: range["skip_logic"], else: false
            end)
          end
        "multiple-choice" ->
          step
          |> Map.get("choices")
          |> Enum.find(fn choice -> choice["value"] == reply_value end)
          |> Map.get("skip_logic")
        "explanation" ->
          step["skip_logic"]
        "flag" ->
          step["skip_logic"]
        "language-selection" ->
          nil
      end

    case skip_logic do
      nil ->
        flow.current_step + 1
      "end" ->
        flow |> end_flow
      next_id ->
        next_step_index =
          flow.questionnaire.steps
          |> Enum.find_index(fn istep -> istep["id"] == next_id end)

        if (!next_step_index || flow.current_step > next_step_index) do
          raise "Skip logic: invalid step id."
        else
          next_step_index
        end
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

  defp accept_reply(flow = %Flow{current_step: nil}, :answer) do
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
    reply = reply |> clean_string

    step = flow.questionnaire.steps |> Enum.at(flow.current_step)

    reply_value = case step["type"] do
                    "multiple-choice" ->
                      choice = step["choices"]
                      |> Enum.find(fn choice ->
                        fetch(:response, flow, choice) |> Enum.any?(fn r -> (r |> clean_string) == reply end)
                      end)
                      if (choice), do: choice["value"], else: nil
                    "numeric" ->
                      num = is_numeric(reply)
                      if (num && is_in_numeric_range(step, num)) || is_refusal_option(step, flow, reply) do
                        reply
                      else
                        nil
                      end
                    "language-selection" ->
                      choices = step["language_choices"]
                      {num, ""} = Integer.parse(reply)
                      (choices |> Enum.at(num)) || (choices |> Enum.at(1))
                  end

    # Select language to use in next questions
    flow =
      if step["type"] == "language-selection" do
        %Flow{flow | language: reply_value}
      else
        flow
      end

    case reply_value do
      nil ->
        if flow.retries >=  @max_retries do
          {%{flow | current_step: flow |> end_flow}, %Reply{}}
        else
          {%{flow | retries: flow.retries + 1}, %Reply{prompts: fetch(:error_msg, flow, step)}}
        end
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
            {:ok, flow, %{state | prompts: (state.prompts || []) ++ fetch(:prompt, flow, step)}}
        end
    end
  end

  defp add_explanation_step_prompt(flow, state) do
    step = flow.questionnaire.steps |> Enum.at(flow.current_step)
    state = %{state | prompts: (state.prompts || []) ++ fetch(:prompt, flow, step)}
    flow = %{flow | current_step: next_step_by_skip_logic(flow, step, nil)}
    eval({flow, state})
  end

  defp add_disposition_to_next_step(flow, state, step) do
    state = %{state | disposition: step["disposition"]}
    flow = %{flow | current_step: next_step_by_skip_logic(flow, step, nil)}
    eval({flow, state})
  end

  defp clean_string(nil), do: ""

  defp clean_string(string) do
    string |> String.trim |> String.downcase
  end

  defp fetch(key, flow, step) do
    # If a key is missing in a language, try with the default one as a replacement
    fetch(key, flow, step, flow.language) ||
      fetch(key, flow, step, flow.questionnaire.default_language)
  end

  defp fetch(:prompt, flow, step = %{"type" => "language-selection"}, _language) do
    step
    |> Map.get("prompt", %{})
    |> Map.get(flow.mode)
    |> split_by_newlines(flow.mode)
  end

  defp fetch(:prompt, flow, step, language) do
    step
    |> Map.get("prompt", %{})
    |> Map.get(language, %{})
    |> Map.get(flow.mode)
    |> split_by_newlines(flow.mode)
  end

  defp fetch(:response, flow, step, language) do
    case step
    |> Map.get("responses", %{})
    |> Map.get(flow.mode, %{}) do
      response when is_map(response) ->
        response |> Map.get(language)
      response ->
        response
    end
  end

  defp fetch(:error_msg, flow, _, language) do
    flow.questionnaire.error_msg
    |> Map.get(language, %{})
    |> Map.get(flow.mode)
    |> split_by_newlines(flow.mode)
  end

  defp split_by_newlines(text, mode) do
    if mode == "sms" && text do
      text |> String.split(Questionnaire.sms_split_separator)
    else
      [text]
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
