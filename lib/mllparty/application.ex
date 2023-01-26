defmodule MLLParty.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ok =
      :telemetry.attach(
        # unique handler id
        "log-client-status-handler",
        [:mllp, :client, :status],
        &LogClientStatusHandler.handle_event/4,
        nil
      )

    children = [
      # Start the Telemetry supervisor
      MLLPartyWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: MLLParty.PubSub},
      # Start the ConnectionHub
      MLLParty.ConnectionHub,
      # Start the Endpoint (http/https)
      MLLPartyWeb.Endpoint
      # Start a worker by calling: MLLParty.Worker.start_link(arg)
      # {MLLParty.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MLLParty.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MLLPartyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
