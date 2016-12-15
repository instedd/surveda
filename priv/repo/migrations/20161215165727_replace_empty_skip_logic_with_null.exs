defmodule Ask.Repo.Migrations.ReplaceEmptySkipLogicWithNull do
  use Ecto.Migration

  defp index_of(enum, field), do: Enum.find_index(enum, fn c -> c == field end)

  def change do
    Ask.Repo.transaction fn ->
      quizzes = Ask.Repo.query!("select * from questionnaires")

      id_index = quizzes.columns |> index_of("id")
      steps_index = quizzes.columns |> index_of("steps")

      quizzes.rows
      |> Enum.each(fn quiz_row ->
        upgraded_steps = upgrade(quiz_row |> Enum.at(steps_index))
        Ask.Repo.query!("update questionnaires set steps = ? where id = ?", [upgraded_steps, quiz_row |> Enum.at(id_index)])
      end)
    end
  end

  def upgrade(steps) do
    steps
    |> Poison.decode!
    |> Enum.map(&upgrade_step/1)
    |> Poison.encode!
  end

  def upgrade_step(step) do
    cond do
      step["type"] == "numeric" && is_list(get_in(step, ["ranges"])) ->
        new_ranges =
          get_in(step, ["ranges"])
          |> Enum.map(&upgrade_skip_logic/1)

        put_in(step, ["ranges"], new_ranges)

      step["type"] == "multiple-choice" && is_list(get_in(step, ["choices"])) ->
        new_choices =
          get_in(step, ["choices"])
          |> Enum.map(&upgrade_skip_logic/1)

        put_in(step, ["choices"], new_choices)

      :else ->
        step
    end
  end

  def upgrade_skip_logic(x) do
    case get_in(x, ["skip_logic"]) do
      '' -> put_in(x, ["skip_logic"], nil)
      _ -> x
    end
  end
end
