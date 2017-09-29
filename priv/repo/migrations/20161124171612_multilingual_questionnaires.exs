defmodule Ask.Repo.Migrations.MultilingualQuestionnaires do
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
    step
    |> add_store
    |> upgrade_prompt
    |> upgrade_choices
  end

  def add_store(step) do
    case Map.get(step, "store") do
      nil -> Kernel.put_in(step, ["store"], "")
      _ -> step
    end
  end

  def upgrade_prompt(step) do
    prompt = Kernel.get_in(step, ["prompt"])

    new_prompt = prompt
                |> replace_audio_with_audio_source
                |> introduce_lang

    Kernel.put_in(step, ["prompt"], new_prompt)
  end

  def upgrade_choices(step) do
    case Kernel.get_in(step, ["choices"]) do
      [] -> step
      choices ->
        new_choices = Enum.map(choices, fn(choice) ->
          choice
          |> add_skip_logic
          |> remove_errors
          |> upgrade_responses
        end)

        Kernel.put_in(step, ["choices"], new_choices)
    end
  end

  def upgrade_responses(choice) do
    responses = Kernel.get_in(choice, ["responses"])

    new_responses = case Kernel.get_in(responses, ["en"]) do
                      nil -> %{"en" => responses}
                      _ -> responses
                    end

    Kernel.put_in(choice, ["responses"], new_responses)
  end

  def add_skip_logic(choice) do
    case Kernel.get_in(choice, ["skip_logic"]) do
      nil -> Kernel.put_in(choice, ["skip_logic"], nil)
      _skip_logic -> choice
    end
  end

  def remove_errors(choice) do
    case Kernel.get_in(choice, ["errors"]) do
      nil -> choice
      _errors ->
        {_errors, new_choice} = Kernel.pop_in(choice, ["errors"])
        new_choice
    end
  end

  def replace_audio_with_audio_source(prompt) do
    case Kernel.get_in(prompt, ["ivr"]) do
      # It is ok for a prompt to not have an IVR prompt
      nil -> prompt

      # An empty IVR prompt at least has audio_source == "tts" and text == ""
      "" -> Kernel.put_in(prompt, ["ivr"], %{"audio_source" => "tts", "text" => ""})

      # At this point IVR should be a map, so we check the structure is sound
      ivr_prompt ->
        case {Map.get(ivr_prompt, "audio"), Map.get(ivr_prompt, "audio_source")} do
          # At the very least, the IVR prompt must have an audio_source == "tts"
          {nil, nil} -> Kernel.put_in(prompt, ["ivr", "audio_source"], "tts")

          # This case is ok
          {nil, _audio_source} -> prompt

          # We must replace audio with audio_source
          {audio, nil} ->
            {_, new_prompt} = prompt
                              |> Kernel.put_in(["ivr", "audio_source"], audio)
                              |> Kernel.pop_in(["ivr", "audio"])
            new_prompt

          # Here "audio" is likely a stalled branch of the map, we just drop it
          {_audio, _audio_source} ->
            {_, new_prompt} = Kernel.pop_in(prompt, ["ivr", "audio"])
            new_prompt
        end
    end
  end

  def introduce_lang(prompt) do
    case Kernel.get_in(prompt, ["en"]) do
      nil -> %{"en" => prompt}
      _ -> prompt
    end
  end
end
