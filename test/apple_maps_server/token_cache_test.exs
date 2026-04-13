defmodule AppleMapsServer.TokenCacheTest do
  use ExUnit.Case, async: false

  alias AppleMapsServer.{TestKey, TokenCache}

  setup do
    bypass = Bypass.open()
    pem = TestKey.pem()

    Application.put_env(:apple_maps_server, :team_id, "T")
    Application.put_env(:apple_maps_server, :key_id, "K")
    Application.put_env(:apple_maps_server, :private_key, pem)
    Application.put_env(:apple_maps_server, :base_url, "http://localhost:#{bypass.port}")

    TokenCache.clear()

    on_exit(fn ->
      for k <- [:team_id, :key_id, :private_key, :base_url],
          do: Application.delete_env(:apple_maps_server, k)
    end)

    %{bypass: bypass}
  end

  test "fetch/0 mints once and reuses cached token", %{bypass: bypass} do
    counter = :counters.new(1, [])

    Bypass.stub(bypass, "GET", "/v1/token", fn conn ->
      :counters.add(counter, 1, 1)

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        200,
        Jason.encode!(%{"accessToken" => "ACCESS_A", "expiresInSeconds" => 1800})
      )
    end)

    assert {:ok, "ACCESS_A"} = TokenCache.fetch()
    assert {:ok, "ACCESS_A"} = TokenCache.fetch()
    assert {:ok, "ACCESS_A"} = TokenCache.fetch()

    assert :counters.get(counter, 1) == 1
  end

  test "fetch/0 refreshes after cache is cleared", %{bypass: bypass} do
    counter = :counters.new(1, [])

    Bypass.stub(bypass, "GET", "/v1/token", fn conn ->
      :counters.add(counter, 1, 1)
      n = :counters.get(counter, 1)

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        200,
        Jason.encode!(%{"accessToken" => "ACCESS_#{n}", "expiresInSeconds" => 1800})
      )
    end)

    assert {:ok, "ACCESS_1"} = TokenCache.fetch()
    TokenCache.clear()
    assert {:ok, "ACCESS_2"} = TokenCache.fetch()
  end

  test "fetch/0 returns error on upstream failure without poisoning state", %{bypass: bypass} do
    Bypass.stub(bypass, "GET", "/v1/token", fn conn ->
      Plug.Conn.resp(conn, 401, Jason.encode!(%{"error" => "invalid_token"}))
    end)

    assert {:error, %AppleMapsServer.Error{status: 401}} = TokenCache.fetch()
  end
end
