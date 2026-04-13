# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-04-13

Initial release.

### Added
- ES256 JWT signing from an Apple Maps `.p8` private key, with the
  `iss` / `iat` / `exp` / `scope: "server_api"` claim set Apple requires.
- `GET /v1/token` access-token exchange.
- `AppleMapsServer.TokenCache` — supervised GenServer that caches the
  access token until ~60 s before expiry.
- Endpoints: `search/2`, `search_autocomplete/2`, `geocode/2`,
  `reverse_geocode/2`, `directions/3`, `etas/3`.
- Optional response decoding (`decode: true`) into `AppleMapsServer.Place` /
  `AppleMapsServer.Coordinate` structs.
- `AppleMapsServer.Error` with status-aware messages.
- Bypass-driven unit tests for auth, HTTP envelope, caching, and decoding.
