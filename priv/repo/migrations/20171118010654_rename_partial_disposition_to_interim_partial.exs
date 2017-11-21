defmodule Ask.Repo.Migrations.RenamePartialDispositionToInterimPartial do
  use Ecto.Migration

  def up do
    update_steps(&upgrade_step/1)
  end

  def down do
    update_steps(&downgrade_step/1)
  end

  def update_steps(update_function) do
    Ask.Repo.transaction fn ->
      quizzes = Ask.Repo.query!("select * from questionnaires")

      id_index = quizzes.columns |> index_of("id")
      steps_index = quizzes.columns |> index_of("steps")

      quizzes.rows
      |> Enum.each(fn quiz_row ->
        updated_steps = update(quiz_row |> Enum.at(steps_index), update_function)
        Ask.Repo.query!("update questionnaires set steps = ? where id = ?", [updated_steps, quiz_row |> Enum.at(id_index)])
      end)
    end
  end

  defp index_of(enum, field), do: Enum.find_index(enum, fn c -> c == field end)

  def update(steps, update_function) do
    steps
    |> Poison.decode!
    |> Enum.map(update_function)
    |> Poison.encode!
  end

  def upgrade_step(step) do
    cond do
      step["type"] == "flag" && step["disposition"] == "partial" ->
        %{step | "disposition" => "interim partial"}
      :else ->
        step
    end
  end

  def downgrade_step(step) do
    cond do
      step["type"] == "flag" && step["disposition"] == "interim partial" ->
        %{step | "disposition" => "partial"}
      :else ->
        step
    end
  end
end
