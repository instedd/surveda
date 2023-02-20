defmodule Ask.Audio do
  use Ask.Model

  alias Ask.Sox

  require Logger

  schema "audios" do
    field :uuid, :string
    field :data, :binary
    field :filename, :string
    field :source, :string, default: "upload"
    # :duration is unused. We should remove it from the model (and DB)
    # seconds
    field :duration, :integer, default: 0

    timestamps()
  end

  @valid_extensions ~w(
    .mp3
    .wav
    .m4a .mp4
    .aac
  )
  @valid_mime_types ~w(
    audio/mpeg
    audio/wave audio/wav audio/x-wav audio/x-pn-wav
    audio/mp4 video/mp4
    audio/aac audio/x-hx-aac-adts
  )
  @aac_mime_types ~w(
    audio/mp4 video/mp4
    audio/aac audio/x-hx-aac-adts
  )
  @stored_audio_extension "mp3"

  def exported_audio_file_name(uuid), do: uuid <> ".#{@stored_audio_extension()}"

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:uuid, :filename, :data])
    |> validate_change(:filename, &validate_file_type/2)
    |> validate_change(:data, &validate_size/2)
  end

  @doc """
  Builds a changeset from an uploaded file, validating its type and size.
  """
  def upload_changeset(upload) do
    path = upload.path
    %{size: size} = File.stat!(path)
    %{^path => mime_type} = Ask.FileInfo.get_info(path)

    data = %{filename: upload.filename, mime_type: mime_type, size: size}
    types = %{filename: :string, mime_type: :string, size: :integer}

    {%{}, types}
    |> cast(data, Map.keys(types))
    |> validate_change(:mime_type, &validate_mime_type/2)
    |> validate_change(:size, &validate_size/2)
  end

  @doc """
  Transcodes the uploaded audio file into MP3 (single channel, 44.1khz) then
  returns params suitable to create an `Ask.Audio`. Note that even MP3 audio
  files will be transcoded to avoid issues with invalid or broken MP3 in
  production.
  """
  def params_from_converted_upload(upload, mime_type) do
    basename = Path.basename(upload.filename, Path.extname(upload.filename))

    case convert(upload.path, mime_type) do
      {:ok, data} ->
        %{
          "uuid" => Ecto.UUID.generate(),
          "data" => data,
          "filename" => "#{basename}.#{@stored_audio_extension}"
        }

      {:error, error} ->
        Logger.warn("Error converting file #{upload.path}: #{error}")
        params_from_upload(upload)
    end
  end

  defp convert(path, mime_type) do
    if Enum.member?(@aac_mime_types, mime_type) do
      Sox.convert_aac(path, @stored_audio_extension)
    else
      Sox.convert(path, @stored_audio_extension)
    end
  end

  defp params_from_upload(upload) do
    {:ok, data} = File.read(upload.path)
    %{"uuid" => Ecto.UUID.generate(), "data" => data, "filename" => upload.filename}
  end

  # FIXME: should only allow `.mp3` extensions.
  def validate_file_type(:filename, filename) do
    if Enum.member?(@valid_extensions, Path.extname(filename)) do
      []
    else
      [filename: "Invalid file type. Allowed types are MP3 and WAV."]
    end
  end

  def validate_mime_type(:mime_type, mime_type) do
    if Enum.member?(@valid_mime_types, mime_type) do
      []
    else
      [filename: "Invalid file. Allowed types are MP3 and WAV."]
    end
  end

  def validate_size(:size, size) do
    if size < 16 * 1024 * 1024 do
      []
    else
      [data: "The file is too big, please do not exceed 16MB."]
    end
  end

  def validate_size(:data, data) do
    validate_size(:size, byte_size(data))
  end

  def mime_type(%Ask.Audio{filename: filename}) do
    case Path.extname(filename) do
      ".wav" -> "audio/wav"
      ".mp3" -> "audio/mpeg"
      _ -> "application/octet-stream"
    end
  end
end
