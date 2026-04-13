defmodule AppleMapsServer.Error do
  @moduledoc "Structured error returned from the Apple Maps Server API."

  defexception [:message, :status, :details]

  @type t :: %__MODULE__{
          message: String.t(),
          status: non_neg_integer() | nil,
          details: term()
        }

  @spec from_http(non_neg_integer(), term()) :: t()
  def from_http(status, body) do
    %__MODULE__{
      message: reason_for(status),
      status: status,
      details: body
    }
  end

  defp reason_for(401), do: "unauthorized — token rejected by Apple Maps Server API"
  defp reason_for(403), do: "forbidden — Maps capability or key configuration issue"
  defp reason_for(422), do: "invalid request parameters"
  defp reason_for(429), do: "rate limited by Apple Maps Server API"
  defp reason_for(status) when status in 500..599, do: "Apple Maps Server API server error"
  defp reason_for(_), do: "Apple Maps Server API request failed"
end
