defmodule Ask.Repo.Migrations.ConvertWavAudiosToMp3 do
  use Ecto.Migration
  import Ecto.Query

  defp tmpfile do
    {mega, sec, micro} = :os.timestamp()
    "/tmp/#{mega}-#{sec}-#{micro}.wav"
  end

  def up do
    from(a in "audios", where: fragment("filename LIKE '%.wav'"), select: [:id, :filename])
    |> Ask.Repo.all()
    |> Enum.each(fn %{id: id, filename: filename} ->
      %{data: wav_data} =
        from(a in "audios", where: a.id == ^id, select: [:data]) |> Ask.Repo.one()

      # Write the WAV to a temporary file
      wav_data_path = tmpfile()
      File.write(wav_data_path, wav_data)

      # Convert the WAV to MP3
      IO.puts("Converting #{filename} (#{byte_size(wav_data)} bytes)")

      case Ask.Sox.convert("wav", wav_data_path, "mp3") do
        {:ok, mp3_data} ->
          IO.puts("Converted #{filename} into MP3 (#{byte_size(mp3_data)} bytes)")

          # Update DB
          from(a in "audios", where: a.id == ^id)
          |> Ask.Repo.update_all(
            set: [data: mp3_data, filename: "#{Path.basename(filename, ".wav")}.mp3"]
          )

        {:error, error} ->
          IO.puts("Error converting #{filename} into MP3: #{error}")
      end

      # Remove temporary file
      File.rm(wav_data_path)
    end)
  end

  def down do
  end
end
