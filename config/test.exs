import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :discrot, DiscrotWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "92GmhLURU0QqB4uuy9ytagV9ZQfgkezZODInCd+gUGMKB4tFkDQNM2tiZdZ3aUcW",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true
