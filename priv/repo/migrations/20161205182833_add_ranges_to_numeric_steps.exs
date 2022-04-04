defmodule Ask.Repo.Migrations.AddRangesToNumericSteps do
  use Ecto.Migration

  defp index_of(enum, field), do: Enum.find_index(enum, fn c -> c == field end)

  def change do
    Ask.Repo.transaction(fn ->
      quizzes = Ask.Repo.query!("select * from questionnaires")

      id_index = quizzes.columns |> index_of("id")
      steps_index = quizzes.columns |> index_of("steps")

      quizzes.rows
      |> Enum.each(fn quiz_row ->
        upgraded_steps = upgrade(quiz_row |> Enum.at(steps_index))

        Ask.Repo.query!("update questionnaires set steps = ? where id = ?", [
          upgraded_steps,
          quiz_row |> Enum.at(id_index)
        ])
      end)
    end)
  end

  def upgrade(steps) do
    steps
    |> Poison.decode!()
    |> Enum.map(&upgrade_step/1)
    |> Poison.encode!()
  end

  def upgrade_step(step) do
    cond do
      step["type"] == "numeric" && !Map.has_key?(step, "ranges") ->
        ranges = [%{"from" => nil, "to" => nil, "skip_logic" => nil}]
        Map.put(step, "ranges", ranges)

      :else ->
        step
    end
  end
end
