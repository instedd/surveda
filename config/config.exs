# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :plug, :types, %{
  "application/vnd.api+json" => ["json-api"]
}

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# General application configuration
config :ask,
  ecto_repos: [Ask.Repo]

# Configures the endpoint
config :ask, AskWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Tu6aeyZlhJeiTQDt7AjOIuk2tblnEnGYHyX/VpIcZi3ctSuE0T25j+BZLPiPMFWL",
  render_errors: [view: AskWeb.ErrorView, accepts: ~w(html json)],
  instrumenters: [Ask.PhoenixInstrumenter],
  pubsub: [name: Ask.PubSub, adapter: Phoenix.PubSub.PG2]

config :ask, :channel,
  providers: %{
    "nuntium" => Ask.Runtime.NuntiumChannel,
    "verboice" => Ask.Runtime.VerboiceChannel
  }

config :ask, Ask.FloipPusher,
  poll_interval_in_minutes: {:system, "FLOIP_PUSHER_POLL_INTERVAL_IN_MINUTES", 15}

config :ask, Ask.Runtime.SurveyBroker,
  batch_size: {:system, "BROKER_BATCH_SIZE", 10000},
  batch_limit_per_minute: {:system, "BROKER_BATCH_LIMIT_PER_MINUTE", 100},
  initial_valid_respondent_rate: {:system, "INITIAL_VALID_RESPONDENT_RATE", 100},
  initial_eligibility_rate: {:system, "INITIAL_ELIGIBILITY_RATE", 100},
  initial_response_rate: {:system, "INITIAL_RESPONSE_RATE", 100}

config :ask, :ffmpeg, bin: System.get_env("FFMPEG_BINARY") || "ffmpeg"

config :ask, Ask.UrlShortener,
  url_shortener_api_key: {:system, "URL_SHORTENER_API_KEY"},
  url_shortener_service: {:system, "URL_SHORTENER_SERVICE", "https://svy.in"}

config :ask, Ask.Runtime.QuestionnaireSimulatorStore,
  simulation_ttl: {:system, "SIMULATION_TTL", 5}

config :ask, AskWeb.Email,
  smtp_from_address: {:system, "SMTP_FROM_ADDRESS", "InSTEDD Surveda <noreply@instedd.org>"}

config :ask, custom_language_names: System.get_env("CUSTOM_LANGUAGE_NAMES")

# Configures Elixir's Logger
config :logger, :console,
  format: "$dateT$timeZ $metadata[$level] $message\n",
  metadata: [:request_id]

version =
  case File.read("VERSION") do
    {:ok, version} -> String.trim(version)
    {:error, :enoent} -> "#{Mix.Project.config()[:version]}-#{Mix.env()}"
  end

config :ask, version: version

config :ask, intercom_app_id: System.get_env("INTERCOM_APP_ID")

sentry_enabled = String.length(System.get_env("SENTRY_DSN") || "") > 0

config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: Mix.env() || :dev,
  included_environments: if(sentry_enabled, do: ~w(prod)a, else: []),
  release: version

# %% Coherence Configuration %%   Don't remove this line
config :coherence,
  user_schema: Ask.User,
  repo: Ask.Repo,
  module: Ask,
  web_module: AskWeb,
  router: AskWeb.Router,
  password_hashing_alg: Comeonin.Bcrypt,
  messages_backend: AskWeb.Coherence.Messages,
  # registration_permitted_attributes: ["email", "name", "password", "current_password", "password_confirmation"],
  # invitation_permitted_attributes: ["name", "email"],
  # password_reset_permitted_attributes: ["reset_password_token", "password", "password_confirmation"],
  # session_permitted_attributes: ["remember", "email", "password"],
  logged_out_url: "/",
  email_from_name: "Your Name",
  email_from_email: "yourname@example.com",
  opts: [:authenticatable, :confirmable, :recoverable, :registerable, :rememberable]

config :coherence, AskWeb.Coherence.Mailer, adapter: Swoosh.Adapters.Local
# %% End Coherence Configuration %%

config :prometheus, Ask.PrometheusExporter, auth: false

config :ask, Ask.MetricsEndpoint, http: [port: 9980]

config :alto_guisso,
  enabled: System.get_env("GUISSO_ENABLED") == "true",
  base_url: System.get_env("GUISSO_BASE_URL"),
  client_id: System.get_env("GUISSO_CLIENT_ID"),
  client_secret: System.get_env("GUISSO_CLIENT_SECRET"),
  session_controller: AskWeb.Coherence.SessionController

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

if File.exists?("#{__DIR__}/local.exs") && Mix.env() != :test do
  import_config "local.exs"
end
