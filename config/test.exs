import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mllparty, MLLPartyWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "k+CoFnjaJqKGxmwx+iw4kvJG8/DilLZb6Ou+GTAmOAD4Gg61OtUuCM55ZzPQedha",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
