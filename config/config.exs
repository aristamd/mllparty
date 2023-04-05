# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :mllparty,
  app_env: config_env(),
  namespace: MLLParty,
  api_key: "sekret"

# Configures the endpoint
config :mllparty, MLLPartyWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: MLLPartyWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MLLParty.PubSub,
  live_view: [signing_salt: "7l6W3F7D"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$date $time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
