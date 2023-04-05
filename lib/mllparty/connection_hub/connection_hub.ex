defmodule MLLParty.ConnectionHub do
  @moduledoc """
  Root of the ConnectionHub tree, which monitors `MLLP.Client` processes,
  and dispatches messages to and through the correct `MLLP.Client` process.

  This root is a Supervisor, supervising 2 processes:
  - a `Registry`
  - a `DynamicSupervisor` that will supervise all the `ClientWrapper`s

  The supervision tree looks like this:
  ```
  MLLParty.ConnectionHub
  ├── Registry
  └── DynamicSupervisor
      ├── ClientWrapper
      │   └── MLLP.Client (e.g. 127.0.0.1:6090)
      └── ClientWrapper
          └── MLLP.Client (e.g. 10.10.10.120:6090)
  ```

  Upon boot, after this process's 2 children have started, any
  pre-configured client connections will be started.
  """

  use Supervisor

  require Logger

  alias MLLParty.ConnectionHub.ClientWrapper

  @default_connection_wait_time Application.compile_env(
                                  :mllparty,
                                  :default_connection_wait_time,
                                  10_000
                                )

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {DynamicSupervisor, name: MLLPClientSupervisor, strategy: :one_for_one},
      {Registry, keys: :unique, name: __MODULE__.ClientRegistry},
      {Task, fn -> start_boot_clients() end}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  @doc """
  Sends a message to the client connection process for the given `ip` and `port`.
  """
  def send_message(ip, port, message, opts \\ []) do
    pid =
      case start_client(ip, port) do
        {:ok, pid} ->
          pid

        {:error, {:already_started, pid}} ->
          pid
      end

    wait_for_client_to_connect(pid)

    Logger.debug("[sender] Sending message to client #{ip}:#{port}: #{inspect(message)}")
    ClientWrapper.send_message(pid, message)
  end

  @doc """
  Returns a list of all client connections, with their status.

  Example:

      iex> MLLParty.ConnectionHub.list_clients()
      [
        %{
          endpoint: "127.0.0.1:6090",
          ip: "127.0.0.1",
          port: "6090",
          connected: true,
          pending_reconnect: false
        }
      ]
  """
  def list_clients() do
    for {_name, pid, _, _} <- Supervisor.which_children(MLLPClientSupervisor) do
      ClientWrapper.client_status(pid)
    end
  end

  @doc """
  Starts a client connection process to the given `ip` and `port`.
  """
  def start_client(ip, port) do
    DynamicSupervisor.start_child(
      MLLPClientSupervisor,
      MLLParty.ConnectionHub.ClientWrapper.child_spec(ip, port)
    )
  end

  @doc """
  Stops a client connection process to the given `ip` and `port`.
  """
  def stop_client(ip, port) when is_binary(ip) do
    {:via, Registry, {registry_name, process_key}} = ClientWrapper.process_name(ip, port)

    case Registry.lookup(registry_name, process_key) do
      [] ->
        Logger.info("Failed to stop client: Client connection not found: #{ip}:#{port}")
        {:error, :not_found}

      [{client_wrapper_pid, _}] ->
        DynamicSupervisor.terminate_child(
          MLLPClientSupervisor,
          client_wrapper_pid
        )

        Logger.info("Stopped client: #{ip}:#{port}")
    end
  end

  def reset() do
    for {_name, client_wrapper_pid, _, _} <- Supervisor.which_children(MLLPClientSupervisor) do
      DynamicSupervisor.terminate_child(
        MLLPClientSupervisor,
        client_wrapper_pid
      )
    end
  end

  defp start_boot_clients() do
    boot_clients = Application.get_env(:mllparty, :boot_clients, [])
    Logger.info("Starting boot client connections: #{inspect(boot_clients)}")

    for {ip, port} <- boot_clients do
      {reply, pid} = start_client(ip, port)
      wait_for_client_to_connect(pid)
    end
  end

  defp wait_for_client_to_connect(
         client_wrapper_pid,
         wait_ms \\ @default_connection_wait_time,
         sleep_interval_ms \\ 300
       ) do
    %{endpoint: endpoint, connected: connected} = ClientWrapper.client_status(client_wrapper_pid)

    cond do
      connected == true ->
        :ok

      wait_ms <= 0 ->
        :timeout

      true ->
        Logger.info("[sender] Waiting for client to connect: #{endpoint}")
        Process.sleep(sleep_interval_ms)

        wait_for_client_to_connect(
          client_wrapper_pid,
          wait_ms - sleep_interval_ms,
          sleep_interval_ms
        )
    end
  end
end
