defmodule Guisso.OAuth.Strategy.TokenExchange do
  use OAuth2.Strategy

  def get_token(client, params, _headers) do
    client
    |> put_param(:grant_type, "token_exchange")
    |> put_param(:client_id, client.client_id)
    |> put_param(:client_secret, client.client_secret)
    |> put_param(:access_token, params[:access_token])
  end
end
