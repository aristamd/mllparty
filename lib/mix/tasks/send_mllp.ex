defmodule Mix.Tasks.SendMllp do
  @moduledoc """
  Sends a test HL7 message via MLLP

  Usage:

      mix send_mllp mllp://0.0.0.0:2595 "test|hl7|message"
  """
  @shortdoc "Sends test message"

  use Mix.Task

  @impl Mix.Task
  def run(["mllp://" <> endpoint]) do
    run(["mllp://" <> endpoint, HL7.Examples.wikipedia_sample_hl7()])
  end

  # Map of persistent connections (endpoint => client pid)
  # Example { "127.0.0.1:3000" => #PID<1>, "127.0.0.1:4000" => #PID<2> }
  @connections %{}

  def run(["mllp://" <> endpoint, message]) do
    [ip, port] = String.split(endpoint, ":")
    port = String.to_integer(port)
    message = HL7.Message.new(message)

    # Check for an existing client for this endpoint
    if Map.has_key?(@connections, endpoint) do
      # Reconnect to the endpoint, if needed
      unless MLLP.Client.is_connected?(@connections[endpoint]) do
        MLLP.Client.reconnect(@connections[endpoint])
      end
    else
      # Make a new connection
      {:ok, client_pid} = MLLP.Client.start_link(ip, port)
      @connections = Map.put(@connections, endpoint, client_pid)
    end

    # Send message to the endpoint
    resp = MLLP.Client.send(@connections[endpoint], message)

    Mix.shell().info(inspect(resp))
  end

  def run(_args) do
    Mix.shell().error("Usage: mix send_mllp mllp://<ip>:<port> <hl7_message>")
  end
end
