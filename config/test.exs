use Mix.Config

# Configure your database
config :f3load, F3load.Repo,
  username: "postgres",
  password: "postgres",
  database: "f3load_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :f3load, F3loadWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
