defmodule AppleMapsServer.Decoder do
  @moduledoc """
  Converts raw Apple Maps Server JSON into typed structs.

  Decoding is opt-in per call with `decode: true`. The raw-map response
  remains available by default so fields Apple adds later pass through
  untouched.
  """

  alias AppleMapsServer.{Coordinate, Place}

  @doc "Decode a response body into structs where shapes are known."
  def decode(%{"results" => results} = body) when is_list(results) do
    Map.put(body, "results", Enum.map(results, &decode_place/1))
  end

  def decode(body), do: body

  defp decode_place(map) when is_map(map) do
    %Place{
      name: map["name"],
      formatted_address_lines: map["formattedAddressLines"],
      country: map["country"],
      country_code: map["countryCode"],
      coordinate: decode_coordinate(map["coordinate"]),
      display_map_region: map["displayMapRegion"],
      structured_address: map["structuredAddress"],
      poi_category: map["poiCategory"]
    }
  end

  defp decode_place(other), do: other

  defp decode_coordinate(%{"latitude" => lat, "longitude" => lon}) do
    %Coordinate{latitude: lat, longitude: lon}
  end

  defp decode_coordinate(_), do: nil
end
