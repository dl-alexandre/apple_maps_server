defmodule AppleMapsServer.Place do
  @moduledoc "A geocoded place returned by Apple Maps Server API."

  alias AppleMapsServer.Coordinate

  defstruct [
    :name,
    :formatted_address_lines,
    :country,
    :country_code,
    :coordinate,
    :display_map_region,
    :structured_address,
    :poi_category
  ]

  @type t :: %__MODULE__{
          name: String.t() | nil,
          formatted_address_lines: [String.t()] | nil,
          country: String.t() | nil,
          country_code: String.t() | nil,
          coordinate: Coordinate.t() | nil,
          display_map_region: map() | nil,
          structured_address: map() | nil,
          poi_category: String.t() | nil
        }
end
