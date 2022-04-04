defmodule Mix.Tasks.Ask.ConvertWavFilesToMp3InDb do
  use Mix.Task

  alias Ask.{Sox, Audio, Repo}

  import Ecto.Query

  @shortdoc """
  Loops through all wav files in the audios table and converts them to mp3
  """

  defp convert_audio(audio) do
    path = "tmpaudios/#{audio.uuid}.wav"
    File.write(path, audio.data, [:binary])
    mp3_filename = "#{Path.basename(audio.filename, ".wav")}.mp3"

    case Sox.convert("wav", path, "mp3") do
      {:ok, mp3} ->
        case Repo.update(Audio.changeset(audio, %{"data" => mp3, "filename" => mp3_filename})) do
          {:ok, _} ->
            Mix.shell().info("Converted #{audio.id} #{audio.filename}")

          {:error, changeset} ->
            Mix.shell().error(
              "Failed inserting #{audio.id} #{audio.filename}: #{inspect(changeset)}"
            )
        end

      {:error, err} ->
        Mix.shell().error("Failed converting #{audio.id} #{audio.filename}: #{err}")
    end
  end

  def run([]) do
    try do
      Mix.Task.run("app.start")
      File.mkdir_p!("tmpaudios")

      stream = Repo.stream(from a in Audio, where: like(a.filename, "%.wav"), order_by: a.id)

      Repo.transaction(fn ->
        Enum.each(stream, &convert_audio/1)
      end)
    after
      File.rm_rf("tmpaudios")
    end
  end
end
