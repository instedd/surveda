defmodule Ask.Runtime.Flow do
  defstruct current_step: nil, questionnaire: nil, mode: nil
  alias Ask.{Repo, Questionnaire}
  alias __MODULE__

  defmodule Reply do
    defstruct stores: [], prompts: []
  end

  def start(quiz, mode) do
    %Flow{questionnaire: quiz, mode: mode}
  end

  def step(flow, reply \\ nil) do
    flow
    |> accept_reply(reply)
    |> eval
  end

  def retry(flow) do
    {flow, %Reply{}} |> eval
  end

  def dump(flow) do
    %{current_step: flow.current_step, questionnaire_id: flow.questionnaire.id, mode: flow.mode}
  end

  def load(state) do
    quiz = Repo.get(Questionnaire, state["questionnaire_id"])
    %Flow{questionnaire: quiz, current_step: state["current_step"], mode: state["mode"]}
  end

  defp is_numeric(str) do
    case Float.parse(str) do
      {_num, ""} -> true
      {_num, _r} -> false               # _r : remainder_of_bianry
      :error     -> false
    end
  end

  defp next_step_by_skip_logic(flow, step, reply_value) do
    skip_logic =
      step
      |> Map.get("choices")
      |> Enum.find(fn choice -> choice["value"] == reply_value end)
      |> Map.get("skip_logic")

    case skip_logic do
      nil ->
        flow.current_step + 1
      "end" ->
        length(flow.questionnaire.steps)
      next_id ->
        next_step_index =
          flow.questionnaire.steps
          |> Enum.find_index(fn istep -> istep["id"] == next_id end)

        if (!next_step_index || flow.current_step > next_step_index) do
          raise "Skip logic: invalid step id."
        end

        next_step_index
    end
  end

  defp advance_current_step(flow, step, reply_value) do
    next_step =
      cond do
        step["type"] == "numeric" || !reply_value ->
          flow.current_step + 1
        :else ->
          next_step_by_skip_logic(flow, step, reply_value)
      end

    %{flow | current_step: next_step}
  end

  defp accept_reply(flow = %Flow{current_step: nil}, nil) do
    flow = %{flow | current_step: 0}
    {flow, %Reply{}}
  end

  defp accept_reply(%Flow{current_step: nil}, _) do
    raise "Flow was not expecting any reply"
  end

  defp accept_reply(flow, nil) do
    {flow, %Reply{}}
  end

  defp accept_reply(flow, reply) do
    reply = reply |> clean_string

    step = flow.questionnaire.steps |> Enum.at(flow.current_step)

    reply_value = case step["type"] do
                    "multiple-choice" ->
                      choice = step["choices"]
                      |> Enum.find(fn choice ->
                        choice["responses"][flow.mode] |> Enum.any?(fn r -> (r |> clean_string) == reply end)
                      end)
                      if (choice), do: choice["value"], else: nil
                    "numeric" ->
                      if (is_numeric(reply)), do: reply, else: nil
                  end

    flow = flow |> advance_current_step(step, reply_value)

    case reply_value do
      nil ->
        {flow, %Reply{}}
      reply_value ->
        {flow, %Reply{stores: %{step["store"] => reply_value}}}
    end
  end

  defp eval({flow, state}) do
    step = flow.questionnaire.steps |> Enum.at(flow.current_step)
    case step do
      nil ->
        {:end, state}
      step ->
        {:ok, flow, %{state | prompts: [step["prompt"][flow.mode]]}}
    end
  end

  defp clean_string(string) do
    string |> String.trim |> String.downcase
  end
end
