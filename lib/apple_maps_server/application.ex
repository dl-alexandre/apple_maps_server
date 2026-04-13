defmodule AppleMapsServer.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [AppleMapsServer.TokenCache]
    Supervisor.start_link(children, strategy: :one_for_one, name: AppleMapsServer.Supervisor)
  end
end
