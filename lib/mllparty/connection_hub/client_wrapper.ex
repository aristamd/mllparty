defmodule MLLParty.ConnectionHub.ClientWrapper do
  use Supervisor

  @moduledoc """
  This is a Supervisor that supervises a single `MLLP.Client` process.

  We're wrapping the `MLLP.Client` in a Supervisor so that we can
  give it a unique process name (`MLLP.Client` isn't name-able out of the box,
  and we want a unique `MLLP.Client` process for each `{ip, port}` combo so
  that we only maintain 1 persistent connection per endpoint).

  This will allow us to use the `Registry` to look up the `MLLP.Client`
  process by name, and send messages to it.
  """

  require Logger

  def child_spec(ip, port) do
    %{
      id: "#{ip}:#{port}",
      start: {__MODULE__, :start_link, [ip, port]}
    }
  end

  def start_link(ip, port) do
    Supervisor.start_link(__MODULE__, {ip, port}, name: process_name(ip, port))
  end

  @impl true
  def init({ip, port}) do
    children = [
      %{
        id: "#{ip}:#{port}",
        start: {MLLP.Client, :start_link, [ip, port]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def send_message(pid, message) do
    # We're essentially proxying the message to the `MLLP.Client`
    # that we're supervising. We need to get the PID of the
    # `MLLP.Client` process that we're supervising, and then
    # send the message to (and through) it.
    pid
    |> child_client_pid()
    |> MLLP.Client.send(message)
  end

  def client_status(wrapper_pid) do
    # NB: This is relying on the fact that the `MLLP.Client` process id
    #     defined in child_spec is the same as the endpoint string.
    [{endpoint, client_pid, _, [MLLP.Client]}] = Supervisor.which_children(wrapper_pid)
    [ip, port] = String.split(endpoint, ":")

    %{
      endpoint: endpoint,
      ip: ip,
      port: String.to_integer(port),
      connected: MLLP.Client.is_connected?(client_pid)
    }
  end

  def process_name(ip, port) do
    {:via, Registry, {MLLParty.ConnectionHub.ClientRegistry, "#{ip}:#{port}"}}
  end

  defp child_client_pid(client_wrapper_pid) do
    # A little bit of magic here. We're using the `which_children`
    # function to get the PID of the `MLLP.Client` process that
    # is being supervised by this `ClientWrapper` process.
    [{_name, mllp_client_pid, :worker, _module}] = Supervisor.which_children(client_wrapper_pid)
    mllp_client_pid
  end
end
