import Config

config(:elixir, :time_zone_database, Tzdata.TimeZoneDatabase)

config :phoenix, :json_library, Jason

# Configures the endpoint
config :niex, NiexWeb.Endpoint,
  pubsub_server: Niex.PubSub,
  live_view: [signing_salt: "TcaKZjCh"],
  secret_key_base: "jL1VNnAUnm8tgEOpFHRMSdsauPfQ2R/8CPSvu8lphKkvRERimswb4Y1RupHkVasq",
  server: true,
  debug_errors: true,
  check_origin: false,
  http: [port: 3333],
  debug_errors: true,
  check_origin: false

config :phoenix, :plug_init_mode, :runtime
