defmodule MLLParty.ConnectionHub.ClientMonitor do
  use GenServer
  @name __MODULE__

  @moduledoc """
    Module to proactively monitor a client's connection and reconnect as necessary
    Send slack notification if connection goes down for too long, send another when it comes back up
  """

  require Logger

  alias MLLParty.ConnectionHub.ClientWrapper

  @impl true
  def init(_opts), do: {:ok, %{
    down_at: nil,
    down_notification_sent: false
  }}

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  def start_monitor(client_wrapper_pid) do
    %{endpoint: endpoint} = ClientWrapper.client_status(client_wrapper_pid)
    Logger.info("Monitoring connection for #{endpoint}")
    {:ok, pid} = start_link()
    Process.send(pid, {:monitor, client_wrapper_pid}, [])
  end

  @impl true
  def handle_info({:monitor, client_wrapper_pid}, state) do
    %{
      endpoint: endpoint,
      connected: connected,
      pending_reconnect: pending_reconnect
    } = ClientWrapper.client_status(client_wrapper_pid)
    Logger.info("Connected: #{connected}")
    client_pid = ClientWrapper.child_client_pid(client_wrapper_pid)
    # Get current timestamp
    current_timestamp = timestamp()
    # Check the connection status
    {down_at, down_notification_sent} = case connected do
      true ->
        # Connection is up, check if it was down previously
        if state.down_at do
          Logger.info("#{endpoint} connection is up")
          # If a downtime notification was sent, follow up that it's connected again
          if state.down_notification_sent do
            SlackNotification.send_notification("#{endpoint} connection is up")
          end
        end
        # Reset down_at, down_notification_sent
        {nil, false}
      false ->
        # Connection is down, check if it just went down
        if state.down_at == nil do
          Logger.info("#{endpoint} connection is down")
          # Try to reconnect, only if the client is not already reconnecting
          if not pending_reconnect do
            Logger.info("Attempting to reconnect #{endpoint}")
            # Client will periodically attempt to reconnect at it's configured interval
            MLLP.Client.reconnect(client_pid)
          end
          # Return current time in seconds as down_at, false as down_notification_sent
          {current_timestamp, false}
        else
          # The presence of down_at indicates, the connection has been down for a while
          # Calculate the downtime duration
          duration = current_timestamp - state.down_at
          # If duration has been 60 seconds or more, send a slack notification (unless it was already sent)
          sent =
            if duration >= 60 and not state.down_notification_sent do
              message = "#{endpoint} connection has been down for #{duration} seconds"
              Logger.info(message)
              SlackNotification.send_notification(message)
              true
            else
              state.down_notification_sent
            end
          # Return current down_at, true as down_notification_sent
          {state.down_at, sent}
        end
    end
    # Run again after 1 second
    Process.send_after(self(), {:monitor, client_wrapper_pid}, 1000)
    # Update the state
    new_state = Map.merge(state, %{
      down_at: down_at,
      down_notification_sent: down_notification_sent
    })
    {:noreply, new_state}
  end

  # Get the current system timestamp in seconds
  def timestamp do
    {megasec, sec, _microsec} = :os.timestamp
    megasec * 1000000 + sec
  end

end
