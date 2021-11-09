defmodule Ask.Repo do
  use Ecto.Repo, otp_app: :ask

  def reload(%module{id: id}) do
    get(module, id)
  end

  # In Ecto 2.2 we can't stream a query that preloads associations. In order to
  # overcome the issue, we create a chunk back from the stream, and only preload
  # for the given batch of structs, that is eventually flattened.
  #
  # See <https://github.com/danielberkompas/elasticsearch-elixir/issues/54#issuecomment-537691898>.
  def stream_preload(stream, preloads, size \\ 500) do
    stream
    |> Stream.chunk_every(size)
    |> Stream.flat_map(fn batch -> preload(batch, preloads) end)
  end
end
