defmodule Ask.UrlShortener do
  # Returns:
  # - :unavailable if the url shortener is not available due to missing configuration
  # - {:ok, url} if successful
  # - {:error, reason} if not
  def shorten(url) do
    api_key = get_api_key()
    if api_key do
      body = String.to_charlist("{\"longUrl\": \"#{url}\"}")
      url = String.to_charlist("https://www.googleapis.com/urlshortener/v1/url?key=#{api_key}")

      case :httpc.request(:post, { url, [], 'application/json', body },[], []) do
        { :ok, {{ _, 200, _}, _, body }} ->
          {:ok, Poison.decode!(body)["id"]}
        { :ok, {{ _, 400, _ }, _, _ }} ->
          { :error, :bad_request }
        _ ->
          { :error, :unknown }
      end
    else
      :unavailable
    end
  end

  defp get_api_key do
    case Application.get_env(:ask, __MODULE__)[:google_api_key] do
      {:system, env_var} ->
        System.get_env(env_var)
      value -> value
    end
  end
end
