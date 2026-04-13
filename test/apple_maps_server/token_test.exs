defmodule AppleMapsServer.TokenTest do
  use ExUnit.Case, async: true

  alias AppleMapsServer.{Token, TestKey}

  setup do
    %{pem: TestKey.pem()}
  end

  test "generate_jwt/1 signs an ES256 JWT with required header and claims", %{pem: pem} do
    {:ok, jwt} =
      Token.generate_jwt(
        team_id: "TEAM123",
        key_id: "KEY456",
        private_key: pem,
        token_ttl_seconds: 120
      )

    [header_b64, payload_b64, _sig] = String.split(jwt, ".")
    header = header_b64 |> Base.url_decode64!(padding: false) |> Jason.decode!()
    payload = payload_b64 |> Base.url_decode64!(padding: false) |> Jason.decode!()

    assert header["alg"] == "ES256"
    assert header["kid"] == "KEY456"
    assert header["typ"] == "JWT"

    assert payload["iss"] == "TEAM123"
    assert payload["scope"] == "server_api"
    assert is_integer(payload["iat"])
    assert payload["exp"] - payload["iat"] == 120
  end

  test "generate_jwt/1 reports missing team_id", %{pem: pem} do
    assert {:error, {:missing_config, :team_id}} =
             Token.generate_jwt(key_id: "K", private_key: pem)
  end

  test "generate_jwt/1 reports missing key_id", %{pem: pem} do
    assert {:error, {:missing_config, :key_id}} =
             Token.generate_jwt(team_id: "T", private_key: pem)
  end

  test "access_token/1 exchanges JWT for access token", %{pem: pem} do
    bypass = Bypass.open()

    Bypass.expect_once(bypass, "GET", "/v1/token", fn conn ->
      assert ["Bearer " <> jwt] = Plug.Conn.get_req_header(conn, "authorization")
      assert String.split(jwt, ".") |> length() == 3

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        200,
        Jason.encode!(%{"accessToken" => "ACCESS_123", "expiresInSeconds" => 1800})
      )
    end)

    assert {:ok, "ACCESS_123"} =
             Token.access_token(
               team_id: "T",
               key_id: "K",
               private_key: pem,
               base_url: "http://localhost:#{bypass.port}"
             )
  end

  test "access_token/1 surfaces 401 as Error struct", %{pem: pem} do
    bypass = Bypass.open()

    Bypass.expect_once(bypass, "GET", "/v1/token", fn conn ->
      Plug.Conn.resp(conn, 401, Jason.encode!(%{"error" => "invalid_token"}))
    end)

    assert {:error, %AppleMapsServer.Error{status: 401}} =
             Token.access_token(
               team_id: "T",
               key_id: "K",
               private_key: pem,
               base_url: "http://localhost:#{bypass.port}"
             )
  end
end
