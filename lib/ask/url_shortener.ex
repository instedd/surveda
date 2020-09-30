defmodule Ask.UrlShortener do
  alias Ask.ConfigHelper
  # Returns:
  # - :unavailable if the url shortener is not available due to missing configuration
  # - {:ok, url} if successful
  # - {:error, reason} if not
  def shorten(url) do
    api_key = get_api_key()
    if api_key do
      url = String.to_charlist("#{get_shortener_service()}/api/v1/links?url=#{url}")
      api_key_header = {String.to_charlist("x-api-key"), String.to_charlist(api_key)}
      case :httpc.request(:post, {url, [api_key_header], [], []},[], []) do
        { :ok, {{ _, 200, _}, _, body }} ->
          {:ok, "#{build_short_url(get_shortener_service(), body)}"}
        { :ok, {{ _, 400, _ }, _, _ }} ->
          { :error, :bad_request }
        _ ->
          { :error, :unknown }
      end
    else
      :unavailable
    end
  end

  def shorten_or_log_error(url) do
    case shorten(url) do
      {:ok, shortened_url} ->
        shortened_url
      {:error, reason} ->
        Ask.Logger.error "Couldn't shorten url. Reason: #{reason}"
        url
      :unavailable ->
        url
    end
  end

  def build_short_url(host, response_body) do
    "#{host}/#{Poison.decode!(response_body)["key"]}"
  end

  defp get_api_key, do: ConfigHelper.get_config(__MODULE__, :url_shortener_api_key)

  defp get_shortener_service, do: ConfigHelper.get_config(__MODULE__, :url_shortener_service)

end
