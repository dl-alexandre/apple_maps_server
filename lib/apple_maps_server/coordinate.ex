defmodule AppleMapsServer.Coordinate do
  @moduledoc "A latitude/longitude pair."

  @enforce_keys [:latitude, :longitude]
  defstruct [:latitude, :longitude]

  @type t :: %__MODULE__{latitude: float(), longitude: float()}
end
