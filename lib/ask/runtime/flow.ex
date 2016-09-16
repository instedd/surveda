defmodule Ask.Runtime.Flow do
  defstruct current_step: nil, questionnaire: nil
  alias Ask.{Repo, Questionnaire}

  def start(quiz) do
    %Ask.Runtime.Flow{questionnaire: quiz}
  end

  def step(flow, _reply \\ nil) do
    flow
    |> move_next()
    |> current_step()
  end

  def dump(flow) do
    %{current_step: flow.current_step, questionnaire_id: flow.questionnaire.id}
  end

  def load(state) do
    quiz = Repo.get(Questionnaire, state["questionnaire_id"])
    %Ask.Runtime.Flow{questionnaire: quiz, current_step: state["current_step"]}
  end

  defp move_next(flow = %Ask.Runtime.Flow{current_step: nil}) do
    case flow.questionnaire.steps do
      [] -> %{flow | current_step: :end}
      _ -> %{flow | current_step: 0}
    end
  end

  defp move_next(flow) do
    next_step = flow.current_step + 1
    if Enum.count(flow.questionnaire.steps) > next_step do
      %{flow | current_step: next_step}
    else
      %{flow | current_step: :end}
    end
  end

  defp current_step(_flow = %Ask.Runtime.Flow{current_step: :end}) do
    :end
  end

  defp current_step(flow) do
    step = flow.questionnaire.steps |> Enum.at(flow.current_step)
    {:ok, flow, {:prompt, step["title"]}}
  end
end
