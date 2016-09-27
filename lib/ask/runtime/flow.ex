defmodule Ask.Runtime.Flow do
  defstruct current_step: nil, questionnaire: nil
  alias Ask.{Repo, Questionnaire}
  alias __MODULE__

  defmodule Reply do
    defstruct stores: [], prompts: []
  end

  def start(quiz) do
    %Flow{questionnaire: quiz}
  end

  def step(flow, reply \\ nil) do
    flow
    |> accept_reply(reply)
    |> eval
  end

  def dump(flow) do
    %{current_step: flow.current_step, questionnaire_id: flow.questionnaire.id}
  end

  def load(state) do
    quiz = Repo.get(Questionnaire, state["questionnaire_id"])
    %Flow{questionnaire: quiz, current_step: state["current_step"]}
  end

  defp accept_reply(flow = %Flow{current_step: nil}, nil) do
    flow = %{flow | current_step: 0}
    {flow, %Reply{}}
  end

  defp accept_reply(%Flow{current_step: nil}, _) do
    raise "Flow was not expecting any reply"
  end

  defp accept_reply(flow, reply) do
    reply = reply |> clean_string

    step = flow.questionnaire.steps |> Enum.at(flow.current_step)
    flow = %{flow | current_step: flow.current_step + 1}

    choice = step["choices"] |> Enum.find(fn choice ->
      choice["responses"] |> Enum.any?(fn r -> (r |> clean_string) == reply end)
    end)

    case choice do
      nil ->
        {flow, %Reply{}}
      choice ->
        {flow, %Reply{stores: %{step["store"] => choice["value"]}}}
    end
  end

  defp eval({flow, state}) do
    step = flow.questionnaire.steps |> Enum.at(flow.current_step)
    case step do
      nil ->
        {:end, state}
      step ->
        {:ok, flow, %{state | prompts: [step["title"]]}}
    end
  end

  defp clean_string(string) do
    string |> String.trim |> String.downcase
  end
end
