defmodule AppleMapsServer.ClientTest do
  use ExUnit.Case, async: true

  alias AppleMapsServer.{Client, Error, TestKey}

  setup do
    bypass = Bypass.open()

    opts = [
      team_id: "T",
      key_id: "K",
      private_key: TestKey.pem(),
      base_url: "http://localhost:#{bypass.port}"
    ]

    %{bypass: bypass, opts: opts}
  end

  defp stub_token(bypass) do
    Bypass.stub(bypass, "GET", "/v1/token", fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"accessToken" => "ACCESS"}))
    end)
  end

  test "get/2 sends access token and forwards params", %{bypass: bypass, opts: opts} do
    stub_token(bypass)

    Bypass.expect_once(bypass, "GET", "/v1/search", fn conn ->
      assert ["Bearer ACCESS"] = Plug.Conn.get_req_header(conn, "authorization")
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["q"] == "coffee"

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"results" => []}))
    end)

    assert {:ok, %{"results" => []}} =
             Client.get("/v1/search", Keyword.put(opts, :q, "coffee"))
  end

  test "get/2 maps non-2xx to Error struct", %{bypass: bypass, opts: opts} do
    stub_token(bypass)

    Bypass.expect_once(bypass, "GET", "/v1/geocode", fn conn ->
      Plug.Conn.resp(conn, 422, Jason.encode!(%{"error" => "bad_request"}))
    end)

    assert {:error, %Error{status: 422}} =
             Client.get("/v1/geocode", Keyword.put(opts, :q, "nowhere"))
  end

  test "get/2 maps transport failure", %{bypass: bypass, opts: opts} do
    stub_token(bypass)
    Bypass.down(bypass)

    no_retry = Keyword.put(opts, :req_options, retry: false)

    assert {:error, _reason} =
             Client.get("/v1/search", Keyword.put(no_retry, :q, "x"))
  end

  test "get/2 with decode: true returns Place structs", %{bypass: bypass, opts: opts} do
    stub_token(bypass)

    Bypass.expect_once(bypass, "GET", "/v1/search", fn conn ->
      body = %{
        "results" => [
          %{
            "name" => "Blue Bottle",
            "coordinate" => %{"latitude" => 37.77, "longitude" => -122.41}
          }
        ]
      }

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(body))
    end)

    assert {:ok, %{"results" => [%AppleMapsServer.Place{name: "Blue Bottle"}]}} =
             Client.get(
               "/v1/search",
               opts |> Keyword.put(:q, "coffee") |> Keyword.put(:decode, true)
             )
  end

  test "directions/3 passes origin and destination", %{bypass: bypass, opts: opts} do
    stub_token(bypass)

    Bypass.expect_once(bypass, "GET", "/v1/directions", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["origin"] == "San Francisco, CA"
      assert conn.query_params["destination"] == "Cupertino, CA"

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"routes" => []}))
    end)

    assert {:ok, %{"routes" => []}} =
             AppleMapsServer.directions("San Francisco, CA", "Cupertino, CA", opts)
  end

  test "etas/3 joins destinations with pipe", %{bypass: bypass, opts: opts} do
    stub_token(bypass)

    Bypass.expect_once(bypass, "GET", "/v1/etas", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["origin"] == "37.33,-122.03"
      assert conn.query_params["destinations"] == "37.77,-122.41|37.80,-122.27"

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"etas" => []}))
    end)

    assert {:ok, _} =
             AppleMapsServer.etas(
               "37.33,-122.03",
               ["37.77,-122.41", "37.80,-122.27"],
               opts
             )
  end

  test "reverse_geocode/2 encodes loc param", %{bypass: bypass, opts: opts} do
    stub_token(bypass)

    Bypass.expect_once(bypass, "GET", "/v1/reverseGeocode", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["loc"] == "37.3318,-122.0312"
      Plug.Conn.resp(conn, 200, Jason.encode!(%{"results" => []}))
    end)

    assert {:ok, _} =
             AppleMapsServer.reverse_geocode(
               %{latitude: 37.3318, longitude: -122.0312},
               opts
             )
  end
end
