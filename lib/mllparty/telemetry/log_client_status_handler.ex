defmodule LogClientStatusHandler do
  require Logger

  def handle_event([:mllp, :client, :status], measurements, metadata, _config) do
    message =
      case measurements.status do
        :connected -> "Client connected."
        :disconnected -> "Client disconnected: #{metadata.tcp_error || "(unknown reason)"}"
        _ -> "Client status: #{measurements.status}"
      end

    Logger.info("[monitor] Endpoint: #{metadata.socket_address} - #{message}")
  end
end
