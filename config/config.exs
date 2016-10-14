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

config :ask, Nuntium,
  base_url: System.get_env("NUNTIUM_BASE_URL") || "",
  guisso: [
    base_url: System.get_env("NUNTIUM_GUISSO_BASE_URL") || "",
    client_id: System.get_env("NUNTIUM_CLIENT_ID") || "",
    client_secret: System.get_env("NUNTIUM_CLIENT_SECRET") || "",
    app_id: System.get_env("NUNTIUM_APP_ID") || ""
  ]

config :ask, :channel,
  providers: %{
    "nuntium" => Ask.Runtime.NuntiumChannel
  }

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

config :addict,
  secret_key: "243262243132244543362f4573334a324257346976794e2e7559764675",
  extra_validation: fn ({valid, errors}, user_params) -> {valid, errors} end, # define extra validation here
  user_schema: Ask.User,
  repo: Ask.Repo,
  from_email: "no-reply@example.com", # CHANGE THIS
  not_logged_in_url: "/landing",
  mail_service: nil

version = case File.read("VERSION") do
  {:ok, version} -> String.trim(version)
  {:error, :enoent} -> "#{Mix.Project.config[:version]}-#{Mix.env}"
end

config :ask, version: version

config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  public_dsn: System.get_env("SENTRY_PUBLIC_DSN"),
  environment_name: Mix.env || :dev,
  included_environments: ~w(prod)a,
  use_error_logger: true,
  release: version


if File.exists?("#{__DIR__}/local.exs") do
  import_config "#{__DIR__}/local.exs"
end
