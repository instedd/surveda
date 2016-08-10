# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :ask,
  ecto_repos: [Ask.Repo]

# Configures the endpoint
config :ask, Ask.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Tu6aeyZlhJeiTQDt7AjOIuk2tblnEnGYHyX/VpIcZi3ctSuE0T25j+BZLPiPMFWL",
  render_errors: [view: Ask.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Ask.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
