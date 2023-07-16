defmodule MLLParty.ConnectionHub.ClientMonitor do
  use GenServer

  @moduledoc """
    Module to proactively monitor a client's connection
    Send slack notification if connection goes down for too long, send another when it comes back up
  """

  require Logger

  alias MLLParty.ConnectionHub.ClientWrapper

  def child_spec(ip, port, client_wrapper_pid) do
    %{
      id: "#{ip}:#{port} monitor",
      start: {__MODULE__, :start_link, [ip, port, client_wrapper_pid]}
    }
  end

  @impl true
  def init([ip, port, client_wrapper_pid]) do
    Logger.info("Starting client monitor: #{ip}:#{port}")
    schedule_monitor()
    # Return :ok and initial state
    {:ok,
     %{
       ip: ip,
       port: port,
       client_wrapper_pid: client_wrapper_pid,
       down_at: nil,
       down_notification_sent: false,
       reconnect_attempted: false
     }}
  end

  def start_link(ip, port, client_wrapper_pid) do
    GenServer.start_link(__MODULE__, [ip, port, client_wrapper_pid],
      name: String.to_atom("#{ip}:#{port} monitor")
    )
  end

  @impl true
  def handle_info(:monitor, state) do
    %{
      endpoint: endpoint,
      connected: connected,
    } = ClientWrapper.client_status(state.client_wrapper_pid)

    # Check the connection status
    new_state =
      case connected == true do
        true ->
          # Connection is up
          handle_connection_up(endpoint, state)

        false ->
          # Connection is down
          handle_connection_down(endpoint, connected, state)
      end

    schedule_monitor()
    new_state = Map.merge(state, new_state)
    {:noreply, new_state}
  end

  def handle_connection_up(endpoint, state) do
    # Get current timestamp
    now = DateTime.utc_now()
    # Connection is up, check if it was down previously
    if state.down_at do
      seconds = DateTime.diff(now, state.down_at)

      message =
        "#{endpoint} connection is up. Last down duration: #{TimeUtils.format_seconds(seconds)}."

      Logger.info(message)
      # If a downtime notification was sent, follow up that it's connected again
      if state.down_notification_sent do
        SlackNotification.send_notification(message)
      end
    end

    # Reset down_at, down_notification_sent
    %{down_at: nil, down_notification_sent: false}
  end

  def handle_connection_down(endpoint, connected, state) do
    # Get current timestamp
    now = DateTime.utc_now()
    # Connection is down
    new_state =
      if state.down_at == nil do
        message =
          case connected do
            false ->
              "#{endpoint} connection is down"

            {:unavailable, reason} ->
              "#{endpoint} connection is down (mllp client connection status unavailable, reason: #{reason})"
          end

        Logger.info(message)
        %{down_at: now, down_notification_sent: false}
      else
        # The presence of down_at indicates the connection has been down for a while
        # Calculate the downtime duration
        duration = DateTime.diff(now, state.down_at)

        # If duration has been 60 seconds or more, send a slack notification (unless it was already sent)
        sent =
          if duration >= 60 and not state.down_notification_sent do
            message =
              case connected do
                false ->
                  "#{endpoint} connection has been down for #{duration} seconds"

                {:unavailable, reason} ->
                  "#{endpoint} connection has been down for #{duration} seconds (mllp client connection status unavailable, reason: #{reason})"
              end

            Logger.warn(message)
            SlackNotification.send_notification(message)
            true
          else
            state.down_notification_sent
          end

        %{down_at: state.down_at, down_notification_sent: sent}
      end
    Map.merge(state, new_state)
  end

  def schedule_monitor do
    # Run monitor after 1 second
    Process.send_after(self(), :monitor, 1000)
  end
end
