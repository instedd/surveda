defmodule Ask.Audio do
  use Ask.Web, :model

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
    |> cast(params, [:data, :filename])
    |> validate_change(:filename, &validate_file_type/2)
    |> validate_change(:data, &validate_size/2)
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

  def validate_size(:data, data) do
    size = byte_size(data)
    mb_size = size/:math.pow(2, 20)
    if mb_size < 16 do
      []
    else
      [data: "The file is too big, please do not exceed 16MB."]
    end

  end

end
