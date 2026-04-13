defmodule AppleMapsServer.Token do
  @moduledoc """
  Apple Maps Server token generation and exchange.

  Apple's flow has two steps:

    1. Sign an ES256 JWT with your Maps private key (`.p8`), identifying the
       Maps key via the `kid` header and your Team ID via the `iss` claim.
    2. Exchange that JWT for a short-lived **access token** at `GET /v1/token`.
       That access token is what every subsequent API call must send as its
       `Authorization: Bearer` credential.

  `generate_jwt/1` does step 1; `access_token/1` does both.
  """

  alias AppleMapsServer.{Config, Error}

  @type jwt :: String.t()

  @doc "Build and sign the Apple Maps auth JWT (ES256)."
  @spec generate_jwt(keyword()) :: {:ok, jwt} | {:error, term()}
  def generate_jwt(opts \\ []) do
    config = Config.load(opts)
    now = System.system_time(:second)

    with {:ok, team_id} <- require_field(config.team_id, :team_id),
         {:ok, key_id} <- require_field(config.key_id, :key_id) do
      claims = %{
        "iss" => team_id,
        "iat" => now,
        "exp" => now + config.token_ttl_seconds,
        "scope" => "server_api"
      }

      header = %{
        "alg" => "ES256",
        "kid" => key_id,
        "typ" => "JWT"
      }

      try do
        jwk = Config.private_key_pem!(config) |> JOSE.JWK.from_pem()
        {_, compact} = JOSE.JWT.sign(jwk, header, claims) |> JOSE.JWS.compact()
        {:ok, compact}
      rescue
        e -> {:error, {:token_generation_failed, Exception.message(e)}}
      end
    end
  end

  @doc "Sign a JWT and exchange it for an Apple Maps **access token**."
  @spec access_token(keyword()) :: {:ok, String.t()} | {:error, term()}
  def access_token(opts \\ []) do
    with {:ok, token, _expires_at} <- access_token_with_expiry(opts), do: {:ok, token}
  end

  @doc """
  Like `access_token/1` but also returns the unix-epoch expiry time, for cache use.
  """
  @spec access_token_with_expiry(keyword()) ::
          {:ok, String.t(), integer()} | {:error, term()}
  def access_token_with_expiry(opts \\ []) do
    config = Config.load(opts)

    with {:ok, jwt} <- generate_jwt(opts) do
      req =
        Req.new(
          base_url: config.base_url,
          headers: [{"accept", "application/json"}],
          auth: {:bearer, jwt}
        )
        |> Req.merge(config.req_options)

      case Req.get(req, url: "/v1/token") do
        {:ok, %Req.Response{status: 200, body: %{"accessToken" => token} = body}} ->
          ttl = Map.get(body, "expiresInSeconds", 1800)
          {:ok, token, System.system_time(:second) + ttl}

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, Error.from_http(status, body)}

        {:error, reason} ->
          {:error, {:transport_error, reason}}
      end
    end
  end

  defp require_field(nil, name), do: {:error, {:missing_config, name}}
  defp require_field("", name), do: {:error, {:missing_config, name}}
  defp require_field(value, _), do: {:ok, value}
end
