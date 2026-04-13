defmodule AppleMapsServer do
  @moduledoc """
  Elixir client for the [Apple Maps Server API](https://developer.apple.com/documentation/applemapsserverapi).

  The public surface is intentionally small:

      AppleMapsServer.search("coffee")
      AppleMapsServer.search_autocomplete("cof")
      AppleMapsServer.geocode("1 Infinite Loop, Cupertino, CA")
      AppleMapsServer.reverse_geocode(%{latitude: 37.3318, longitude: -122.0312})
      AppleMapsServer.token()

  ## Configuration

      config :apple_maps_server,
        maps_id: System.get_env("APPLE_MAPS_ID"),
        team_id: System.get_env("APPLE_TEAM_ID"),
        key_id: System.get_env("APPLE_MAPS_KEY_ID"),
        private_key: System.get_env("APPLE_MAPS_PRIVATE_KEY"),
        base_url: "https://maps-api.apple.com",
        token_ttl_seconds: 300

  Every function also accepts per-call `opts` that override the application config.
  """

  alias AppleMapsServer.{Client, Token}

  @type opts :: keyword()
  @type response :: {:ok, map()} | {:error, term()}

  @doc "Return a cached-per-call Apple Maps **access token** (after the JWT → token exchange)."
  @spec token(opts) :: {:ok, String.t()} | {:error, term()}
  def token(opts \\ []), do: Token.access_token(opts)

  @doc "Search for places matching a free-text query. See Apple docs for full parameter list."
  @spec search(String.t(), opts) :: response
  def search(query, opts \\ []) when is_binary(query) do
    Client.get("/v1/search", Keyword.put(opts, :q, query))
  end

  @doc "Return autocomplete suggestions for a partial query."
  @spec search_autocomplete(String.t(), opts) :: response
  def search_autocomplete(query, opts \\ []) when is_binary(query) do
    Client.get("/v1/searchAutocomplete", Keyword.put(opts, :q, query))
  end

  @doc "Forward-geocode a free-text address."
  @spec geocode(String.t(), opts) :: response
  def geocode(address, opts \\ []) when is_binary(address) do
    Client.get("/v1/geocode", Keyword.put(opts, :q, address))
  end

  @doc "Reverse-geocode a coordinate pair."
  @spec reverse_geocode(%{latitude: number(), longitude: number()}, opts) :: response
  def reverse_geocode(%{latitude: lat, longitude: lon}, opts \\ []) do
    Client.get("/v1/reverseGeocode", Keyword.merge(opts, loc: "#{lat},#{lon}"))
  end

  @doc """
  Directions from an origin to a destination. Origin/destination may be a free-text
  address or a `"lat,lon"` string.
  """
  @spec directions(String.t(), String.t(), opts) :: response
  def directions(origin, destination, opts \\ [])
      when is_binary(origin) and is_binary(destination) do
    Client.get("/v1/directions", Keyword.merge(opts, origin: origin, destination: destination))
  end

  @doc """
  ETAs from an origin to up to ten destinations. `destinations` accepts either
  a `"lat,lon|lat,lon"` string or a list of such coordinate strings — the list
  form is joined with the `|` delimiter Apple expects.
  """
  @spec etas(String.t(), String.t() | [String.t()], opts) :: response
  def etas(origin, destinations, opts \\ []) when is_binary(origin) do
    dests =
      case destinations do
        list when is_list(list) -> Enum.join(list, "|")
        str when is_binary(str) -> str
      end

    Client.get("/v1/etas", Keyword.merge(opts, origin: origin, destinations: dests))
  end
end
