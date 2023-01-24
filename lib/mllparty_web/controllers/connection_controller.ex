defmodule MLLPartyWeb.ConnectionController do
  use MLLPartyWeb, :controller

  action_fallback MLLPartyWeb.FallbackController

  def list(conn, _params) do
    json(conn, %{connections: MLLParty.ConnectionHub.list_clients()})
  end
end
