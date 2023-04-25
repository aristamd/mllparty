defmodule MLLPartyWeb.ConnectionController do
  use MLLPartyWeb, :controller

  alias MLLParty.ConnectionHub
  alias MLLParty.Helpers
  require Logger

  action_fallback MLLPartyWeb.FallbackController

  def create(conn, %{"endpoint" => endpoint}) do
    case Helpers.validate_endpoint(endpoint) do
      {:ok, {ip, port}} ->
        ConnectionHub.start_client(ip, port)
        json(conn, %{started: true})

      {:error, :invalid_endpoint} ->
        msg = "Invalid `endpoint` param: #{endpoint}"
        Logger.info(msg)
        {:error, :invalid_request, msg}
    end
  end

  def list(conn, _params) do
    json(conn, %{connections: MLLParty.ConnectionHub.list_clients()})
  end
end
