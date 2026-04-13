defmodule AppleMapsServer.Client do
  @moduledoc false

  alias AppleMapsServer.{Config, Decoder, Error, Token, TokenCache}

  @config_keys [
    :maps_id,
    :team_id,
    :key_id,
    :private_key,
    :private_key_path,
    :base_url,
    :token_ttl_seconds,
    :req_options
  ]

  @meta_keys [:decode]

  @spec get(String.t(), keyword()) :: {:ok, term()} | {:error, term()}
  def get(path, opts) do
    {config_opts, meta, params} = split_opts(opts)
    config = Config.load(config_opts)

    with {:ok, access_token} <- fetch_access_token(config_opts) do
      req =
        Req.new(
          base_url: config.base_url,
          headers: [{"accept", "application/json"}],
          auth: {:bearer, access_token}
        )
        |> Req.merge(config.req_options)

      req
      |> Req.get(url: path, params: Map.new(params))
      |> normalize(meta)
    end
  end

  defp fetch_access_token([]), do: TokenCache.fetch()
  defp fetch_access_token(config_opts), do: Token.access_token(config_opts)

  defp split_opts(opts) do
    {config, rest} = Keyword.split(opts, @config_keys)
    {meta, params} = Keyword.split(rest, @meta_keys)
    {config, meta, params}
  end

  defp normalize({:ok, %Req.Response{status: status, body: body}}, meta)
       when status in 200..299 do
    if Keyword.get(meta, :decode, false) do
      {:ok, Decoder.decode(body)}
    else
      {:ok, body}
    end
  end

  defp normalize({:ok, %Req.Response{status: status, body: body}}, _meta),
    do: {:error, Error.from_http(status, body)}

  defp normalize({:error, reason}, _meta),
    do: {:error, {:transport_error, reason}}
end
