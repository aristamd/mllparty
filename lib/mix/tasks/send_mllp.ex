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

  def run(["mllp://" <> endpoint, message]) do
    [ip, port] = String.split(endpoint, ":")
    port = String.to_integer(port)
    message = HL7.Message.new(message)

    # Send message to the endpoint
    resp =
      MLLParty.ConnectionHub.send_message(ip, port, message, wait_for_client_to_connect: true)

    Mix.shell().info(inspect(resp))
  end

  def run(_args) do
    Mix.shell().error("Usage: mix send_mllp mllp://<ip>:<port> <hl7_message>")
  end
end
