# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :plug, :types, %{
  "application/vnd.api+json" => ["json-api"]
}

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Poison

# General application configuration
config :ask,
  ecto_repos: [Ask.Repo]

if System.get_env("DISABLE_REPO_TIMEOUT") == "true" do
  config :ask, Ask.Repo, timeout: :infinity
end

# Configures the endpoint
config :ask, Ask.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Tu6aeyZlhJeiTQDt7AjOIuk2tblnEnGYHyX/VpIcZi3ctSuE0T25j+BZLPiPMFWL",
  render_errors: [view: Ask.ErrorView, accepts: ~w(html json)],
  instrumenters: [Ask.PhoenixInstrumenter],
  pubsub: [name: Ask.PubSub,
           adapter: Phoenix.PubSub.PG2]

config :ask, :channel,
  providers: %{
    "nuntium" => Ask.Runtime.NuntiumChannel,
    "verboice" => Ask.Runtime.VerboiceChannel
  }

config :ask, Ask.FloipPusher,
  poll_interval_in_minutes: {:system, "FLOIP_PUSHER_POLL_INTERVAL_IN_MINUTES", 15}

config :ask, Ask.Runtime.Broker,
  batch_size: {:system, "BROKER_BATCH_SIZE", 10000},
  batch_limit_per_minute: {:system, "BROKER_BATCH_LIMIT_PER_MINUTE", 100},
  initial_valid_respondent_rate: {:system, "INITIAL_VALID_RESPONDENT_RATE", 100},
  initial_eligibility_rate: {:system, "INITIAL_ELIGIBILITY_RATE", 100},
  initial_response_rate: {:system, "INITIAL_RESPONSE_RATE", 100}

config :ask, :sox,
  bin: System.get_env("SOX_BINARY") || "sox"

config :ask, Ask.UrlShortener,
  url_shortener_api_key: {:system, "URL_SHORTENER_API_KEY"},
  url_shortener_service: {:system, "URL_SHORTENER_SERVICE", "https://svy.in"}

config :ask, Ask.Runtime.QuestionnaireSimulatorStore, simulation_ttl: {:system, "SIMULATION_TTL", 5}

config :ask, Ask.Email,
  smtp_from_address: {:system, "SMTP_FROM_ADDRESS", "InSTEDD Surveda <noreply@instedd.org>"}

# Configures Elixir's Logger
config :logger, :console,
  format: "$dateT$timeZ $metadata[$level] $message\n",
  metadata: [:request_id]

version = case File.read("VERSION") do
  {:ok, version} -> String.trim(version)
  {:error, :enoent} -> "#{Mix.Project.config[:version]}-#{Mix.env}"
end

config :ask, version: version

config :ask, intercom_app_id: System.get_env("INTERCOM_APP_ID")

sentry_enabled = String.length(System.get_env("SENTRY_DSN") || "") > 0

config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: Mix.env || :dev,
  included_environments: (if sentry_enabled, do: ~w(prod)a, else: []),
  release: version

# %% Coherence Configuration %%   Don't remove this line
config :coherence,
  user_schema: Ask.User,
  repo: Ask.Repo,
  module: Ask,
  logged_out_url: "/",
  email_from_name: "Your Name",
  email_from_email: "yourname@example.com",
  opts: [:authenticatable, :recoverable, :confirmable, :registerable, :rememberable]

config :coherence, Ask.Coherence.Mailer,
  adapter: Swoosh.Adapters.Local
# %% End Coherence Configuration %%

config :prometheus, Ask.PrometheusExporter,
  auth: false

config :ask, Ask.MetricsEndpoint,
  http: [port: 9980]

config :alto_guisso,
  enabled: System.get_env("GUISSO_ENABLED") == "true",
  base_url: System.get_env("GUISSO_BASE_URL"),
  client_id: System.get_env("GUISSO_CLIENT_ID"),
  client_secret: System.get_env("GUISSO_CLIENT_SECRET")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

if File.exists?("#{__DIR__}/local.exs") && Mix.env != :test do
  import_config "local.exs"
end
