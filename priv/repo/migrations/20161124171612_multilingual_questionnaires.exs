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
    |> replace_audio_with_audio_source
  end

  def add_store(step) do
    case Map.get(step, "store") do
      nil -> Kernel.put_in(step, ["store"], "")
      _ -> step
    end
  end

  def replace_audio_with_audio_source(step) do
    IO.inspect step
    case Kernel.get_in(step, ["prompt", "ivr"]) do
      # It is ok for a step to not have an IVR prompt
      nil -> step

      # An empty IVR prompt at least has audio_source == "tts" and text == ""
      "" -> Kernel.put_in(step, ["prompt", "ivr"], %{"audio_source" => "tts", "text" => ""})

      # At this point IVR should be a map, so we check the structure is sound
      ivr_prompt ->
        case {Map.get(ivr_prompt, "audio"), Map.get(ivr_prompt, "audio_source")} do
          # At the very least, the IVR prompt must have an audio_source == "tts"
          {nil, nil} -> Kernel.put_in(step, ["prompt", "ivr", "audio_source"], "tts")

          # This case is ok
          {nil, _audio_source} -> step

          # We must replace audio with audio_source
          {audio, nil} ->
            {_, new_step} = step
                            |> Kernel.put_in(["prompt", "ivr", "audio_source"], audio)
                            |> Kernel.pop_in(["prompt", "ivr", "audio"])
            new_step

          # Here "audio" is likely a stalled branch of the map, we just drop it
          {_audio, _audio_source} ->
            {_, new_step} = Kernel.pop_in(step, ["prompt", "ivr", "audio"])
            new_step
        end
    end
  end
end
