defmodule AppleMapsServer.TestKey do
  @moduledoc false

  @doc "Generate an ephemeral ES256 (P-256) private key in PEM form for tests."
  def pem do
    jwk = JOSE.JWK.generate_key({:ec, "P-256"})
    {_, pem} = JOSE.JWK.to_pem(jwk)
    pem
  end
end
