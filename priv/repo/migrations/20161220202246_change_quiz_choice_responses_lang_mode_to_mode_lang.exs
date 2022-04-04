defmodule Ask.Repo.Migrations.ChangeQuizChoiceResponsesLangModeToModeLang do
  use Ecto.Migration

  def up do
    update_steps(&upgrade_step/1)
  end

  def down do
    update_steps(&downgrade_step/1)
  end

  def update_steps(update_function) do
    Ask.Repo.transaction(fn ->
      quizzes = Ask.Repo.query!("select * from questionnaires")

      id_index = quizzes.columns |> index_of("id")
      steps_index = quizzes.columns |> index_of("steps")

      quizzes.rows
      |> Enum.each(fn quiz_row ->
        updated_steps = update(quiz_row |> Enum.at(steps_index), update_function)

        Ask.Repo.query!("update questionnaires set steps = ? where id = ?", [
          updated_steps,
          quiz_row |> Enum.at(id_index)
        ])
      end)
    end)
  end

  defp index_of(enum, field), do: Enum.find_index(enum, fn c -> c == field end)

  def update(steps, update_function) do
    steps
    |> Poison.decode!()
    |> Enum.map(update_function)
    |> Poison.encode!()
  end

  def upgrade_step(step) do
    upgrade_step_responses(step, &upgrade_responses/1)
  end

  def downgrade_step(step) do
    upgrade_step_responses(step, &downgrade_responses/1)
  end

  def upgrade_step_responses(step, update_function) do
    cond do
      step["type"] == "multiple-choice" && is_list(get_in(step, ["choices"])) ->
        new_choices =
          get_in(step, ["choices"])
          |> Enum.map(fn choice ->
            new_responses = update_function.(get_in(choice, ["responses"]))

            put_in(choice, ["responses"], new_responses)
          end)

        put_in(step, ["choices"], new_choices)

      :else ->
        step
    end
  end

  def upgrade_responses(responses) do
    responses
    |> Map.keys()
    |> Enum.reduce(%{sms: %{}, ivr: []}, fn lang, new_response ->
      new_response = %{
        new_response
        | sms: Map.put(new_response[:sms], lang, responses[lang]["sms"])
      }

      if responses[lang]["ivr"] do
        %{new_response | ivr: responses[lang]["ivr"]}
      else
        new_response
      end
    end)
  end

  def downgrade_responses(%{"sms" => sms, "ivr" => ivr}) do
    sms
    |> Map.keys()
    |> Enum.reduce(%{}, fn lang, new_response ->
      Map.put(new_response, lang, %{sms: sms[lang], ivr: ivr})
    end)
  end

  def downgrade_responses(response), do: response
end
