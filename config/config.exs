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

config :ask, Verboice,
  base_url: System.get_env("VERBOICE_BASE_URL") || "",
  guisso: [
    base_url: System.get_env("VERBOICE_GUISSO_BASE_URL") || "",
    client_id: System.get_env("VERBOICE_CLIENT_ID") || "",
    client_secret: System.get_env("VERBOICE_CLIENT_SECRET") || "",
    app_id: System.get_env("VERBOICE_APP_ID") || ""
  ]

config :ask, :channel,
  providers: %{
    "nuntium" => Ask.Runtime.NuntiumChannel,
    "verboice" => Ask.Runtime.VerboiceChannel
  }

# Configures Elixir's Logger
config :logger, :console,
  format: "$dateT$timeZ $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

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

config :appsignal, :config,
  name: :ask,
  env: Mix.env || :dev,
  revision: version

if File.exists?("#{__DIR__}/local.exs") && Mix.env != :test do
  import_config "#{__DIR__}/local.exs"
end

# %% Coherence Configuration %%   Don't remove this line
config :coherence,
  user_schema: Ask.User,
  repo: Ask.Repo,
  module: Ask,
  logged_out_url: "/",
  email_from_name: "Your Name",
  email_from_email: "yourname@example.com",
  opts: [:authenticatable, :recoverable, :confirmable, :registerable]

config :coherence, Ask.Coherence.Mailer,
  adapter: Swoosh.Adapters.Local
# %% End Coherence Configuration %%
