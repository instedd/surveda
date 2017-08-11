defmodule Ask.Audio do
  use Ask.Web, :model

  alias Ask.Sox

  require Logger

  schema "audios" do
    field :uuid, :string
    field :data, :binary
    field :filename, :string
    field :source, :string, default: "upload"
    field :duration, :integer, default: 0 # seconds

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:uuid, :filename, :data])
    |> validate_change(:filename, &validate_file_type/2)
    |> validate_change(:data, &validate_size/2)
  end

  def upload_changeset(upload) do
    %{size: size} = File.stat!(upload.path)
    data = %{filename: upload.filename, size: size}
    types = %{filename: :string, size: :integer}

    {%{}, types}
    |> cast(data, Map.keys(types))
    |> validate_change(:filename, &validate_file_type/2)
    |> validate_change(:size, &validate_size/2)
  end

  def params_from_converted_upload(upload) do
    case Path.extname(upload.filename) do
      ".wav" -> case Sox.convert("wav", upload.path, "mp3") do
                  {:ok, data} ->
                    %{"uuid" => Ecto.UUID.generate, "data" => data, "filename" => "#{Path.basename(upload.filename, ".wav")}.mp3"}
                  {:error, error} ->
                    Logger.warn("Error converting file #{upload.path}: #{error}")
                    params_from_upload(upload)
                end
      _ -> params_from_upload(upload)
    end
  end

  defp params_from_upload(upload) do
    {:ok, data} = File.read(upload.path)
    %{"uuid" => Ecto.UUID.generate, "data" => data, "filename" => upload.filename}
  end

  def validate_file_type(:filename, filename) do
    valid_extensions = ~w(.mp3 .wav)
    extension = Path.extname(filename)
    valid_type = valid_extensions |> Enum.member?(extension)

    if valid_type do
      []
    else
      [filename: "Invalid file type. Allowed types are MPEG and WAV."]
    end
  end

  def validate_size(:size, size) do
    mb_size = size/:math.pow(2, 20)
    if mb_size < 16 do
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
