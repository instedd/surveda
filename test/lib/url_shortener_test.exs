defmodule AskWeb.UrlShortenerTest do
  use ExUnit.Case
  alias Ask.UrlShortener

  test "build short url from shorter response" do
    body = """
    {"key": "P9CKRx","url": "https://google.com"}
    """

    short_url = UrlShortener.build_short_url("test.host", body)

    assert short_url == "test.host/P9CKRx"
  end
end
