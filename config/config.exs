# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :Exload,
  ecto_repos: [Exload.Repo]

# Configures the endpoint
config :Exload, ExloadWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "BxLAgAEkgDs4af56M86t2zgKEMe8Psr15HgdZYRzjEH0CAvvu1weQyTEa1gnWNBI",
  render_errors: [view: ExloadWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Exload.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
