# AppleMapsServer

Elixir client for the [Apple Maps Server API](https://developer.apple.com/documentation/applemapsserverapi).

## Features

- ES256 JWT signing and `/v1/token` access-token exchange
- Supervised token cache (no per-call token minting)
- Place search, autocomplete, forward/reverse geocoding, directions, ETAs
- Optional response decoding into typed structs (`Place`, `Coordinate`)
- Typed errors with status-aware messages

## Installation

```elixir
def deps do
  [
    {:apple_maps_server, "~> 0.1.0"}
  ]
end
```

## Configuration

Get a Maps identifier and private key in your Apple Developer account
([Apple's walkthrough](https://developer.apple.com/documentation/applemapsserverapi/creating-a-maps-identifier-and-a-private-key)),
then:

```elixir
config :apple_maps_server,
  maps_id:          System.get_env("APPLE_MAPS_ID"),
  team_id:          System.get_env("APPLE_TEAM_ID"),
  key_id:           System.get_env("APPLE_MAPS_KEY_ID"),
  private_key:      System.get_env("APPLE_MAPS_PRIVATE_KEY"),
  # or: private_key_path: "/path/to/AuthKey_XXXX.p8"
  base_url:         "https://maps-api.apple.com",
  token_ttl_seconds: 1800
```

Every public function also accepts per-call `opts` that override the
application config — useful in tests or for multi-tenant deployments.
Passing any config key in the opts bypasses the token cache for that call.

## Usage

```elixir
{:ok, res} = AppleMapsServer.search("coffee")
{:ok, res} = AppleMapsServer.search_autocomplete("cof")
{:ok, res} = AppleMapsServer.geocode("1 Infinite Loop, Cupertino, CA")
{:ok, res} = AppleMapsServer.reverse_geocode(%{latitude: 37.3318, longitude: -122.0312})
{:ok, res} = AppleMapsServer.directions("San Francisco, CA", "Cupertino, CA")
{:ok, res} = AppleMapsServer.etas("37.33,-122.03", ["37.77,-122.41", "37.80,-122.27"])
{:ok, tok} = AppleMapsServer.token()
```

### Typed responses

Opt in per call with `decode: true`:

```elixir
{:ok, %{"results" => [%AppleMapsServer.Place{} = place | _]}} =
  AppleMapsServer.geocode("1 Infinite Loop, Cupertino, CA", decode: true)

place.coordinate  #=> %AppleMapsServer.Coordinate{latitude: 37.33, longitude: -122.03}
```

### Errors

| Shape                                             | Meaning                                                  |
|---------------------------------------------------|----------------------------------------------------------|
| `{:error, %AppleMapsServer.Error{status: 401}}`   | Token rejected — check team/key IDs and `.p8`            |
| `{:error, %AppleMapsServer.Error{status: 403}}`   | Maps capability not enabled for the key                  |
| `{:error, %AppleMapsServer.Error{status: 422}}`   | Invalid request parameters                               |
| `{:error, %AppleMapsServer.Error{status: 429}}`   | Rate limited — back off                                  |
| `{:error, {:missing_config, :team_id}}`           | Required config not set                                  |
| `{:error, {:token_generation_failed, reason}}`    | JOSE could not sign (usually malformed `.p8`)            |
| `{:error, {:transport_error, reason}}`            | Network / connection failure                             |

## Integration testing

Integration tests hit the real Apple API and are excluded by default:

```bash
APPLE_MAPS_ID=... \
APPLE_TEAM_ID=... \
APPLE_MAPS_KEY_ID=... \
APPLE_MAPS_PRIVATE_KEY_PATH=/path/to/AuthKey_XXXX.p8 \
mix test --only integration
```

## Troubleshooting

- **401 unauthorized** — JWT rejected. Verify `team_id`, `key_id`, and that
  `private_key` is the `.p8` PEM (contains `BEGIN PRIVATE KEY`). Make sure
  the `scope: "server_api"` claim is present (this library sets it automatically).
- **403 forbidden** — Maps capability not enabled for the key, or the Maps ID
  doesn't match the key.
- **`:token_generation_failed`** — Most often an invalid PEM. `.p8` files
  already include PEM headers; do not re-wrap them.
- **429 rate limited** — Apple throttles aggressively; implement retry/backoff
  in your caller.

## License

MIT — see [LICENSE](LICENSE).
