defmodule MLLPartyWeb.MLLPMessageController do
  use MLLPartyWeb, :controller

  alias MLLParty.Helpers
  require Logger

  action_fallback MLLPartyWeb.FallbackController

  def send(conn, %{"endpoint" => "log", "message" => message}) do
    case HL7.Message.new(message) do
      %HL7.Message{} ->
        Logger.info("Valid HL7 message received: #{message}")
        json(conn, %{sent: true})

      %HL7.InvalidMessage{reason: reason} ->
        msg = "Invalid HL7 in `message` param. Reason: #{reason}"
        Logger.info("#{msg} HL7 message: #{message}")
        {:error, :invalid_request, msg}
    end
  end

  def send(conn, %{"endpoint" => endpoint, "message" => message}) do
    with {:ok, {ip, port}} <- Helpers.validate_endpoint(endpoint),
         %HL7.Message{} = hl7_message <- HL7.Message.new(message) do
      # Send message to the endpoint
      resp = MLLParty.ConnectionHub.send_message(ip, port, hl7_message)

      case resp do
        {:ok, _} ->
          Logger.info("[sender] Message sent successfully to #{ip}:#{port}")
          json(conn, %{sent: true})

        {:ok, _application_resp_type,
         %MLLP.Ack{
           acknowledgement_code: ack_code,
           text_message: text_message,
           hl7_ack_message: hl7_ack_message
         }} ->
          Logger.info("[sender] Message sent successfully to #{ip}:#{port}")

          hl7_resp =
            case hl7_ack_message do
              nil -> nil
              %HL7.Message{} -> to_string(hl7_ack_message)
            end

          json(conn, %{
            sent: true,
            acknowledgement_code: ack_code,
            text_message: text_message,
            hl7_ack_message: hl7_resp
          })

        {:error, %MLLP.Client.Error{reason: :econnrefused, message: message}} ->
          Logger.error("[sender] Failed to send: #{message}")

          conn
          |> put_status(:bad_gateway)
          |> json(%{sent: false, message: message})

        {:error, %MLLP.Client.Error{reason: reason}} ->
          Logger.error("[sender] Failed to send: #{reason}")

          conn
          |> put_status(:internal_server_error)
          |> json(%{sent: false, message: reason})

        {:error, error_type, error_message} ->
          Logger.error(
            "[sender] Failed to send: #{inspect(error_type)} - #{inspect(error_message)}"
          )

          json(conn, %{sent: false})
      end
    else
      {:error, :invalid_endpoint} ->
        msg = "Invalid `endpoint` param: #{endpoint}"
        Logger.info(msg)
        {:error, :invalid_request, msg}

      %HL7.InvalidMessage{reason: reason} ->
        msg = "Invalid HL7 in `message` param. Reason: #{reason}"
        Logger.info(msg)
        {:error, :invalid_request, msg}
    end
  end

  def send(_conn, params) do
    required = ["endpoint", "message"]
    provided = Map.keys(params)
    missing = (required -- provided) |> Enum.join(", ")
    {:error, :invalid_request, "Missing params: #{missing}"}
  end
end
