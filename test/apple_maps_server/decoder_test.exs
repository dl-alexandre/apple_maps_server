defmodule AppleMapsServer.DecoderTest do
  use ExUnit.Case, async: true

  alias AppleMapsServer.{Coordinate, Decoder, Place}

  test "decode/1 turns results into Place structs with Coordinate" do
    body = %{
      "results" => [
        %{
          "name" => "1 Infinite Loop",
          "formattedAddressLines" => ["1 Infinite Loop", "Cupertino, CA"],
          "country" => "United States",
          "countryCode" => "US",
          "coordinate" => %{"latitude" => 37.33, "longitude" => -122.03},
          "displayMapRegion" => %{},
          "structuredAddress" => %{"locality" => "Cupertino"}
        }
      ]
    }

    assert %{"results" => [%Place{} = place]} = Decoder.decode(body)
    assert place.name == "1 Infinite Loop"
    assert place.country_code == "US"
    assert %Coordinate{latitude: 37.33, longitude: -122.03} = place.coordinate
    assert place.structured_address == %{"locality" => "Cupertino"}
  end

  test "decode/1 is a no-op on shapes without results" do
    assert Decoder.decode(%{"foo" => "bar"}) == %{"foo" => "bar"}
  end
end
