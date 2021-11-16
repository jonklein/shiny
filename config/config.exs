import Config

config :logger, :console, format: "$time $metadata[$level] $levelpad$message\n"

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
