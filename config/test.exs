use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ask, Ask.Endpoint,
  http: [port: 4001],
  server: false,
  url: [host: "app.ask.dev", port: 80]

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :ask, Ask.Repo,
  adapter: Ecto.Adapters.MySQL,
  username: "root",
  password: "",
  database: "ask_test",
  hostname: System.get_env("DATABASE_HOST") || "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :ask, Ask.Runtime.Broker,
  batch_size: 10

config :ask, :channel,
  providers: %{
    "test" => Ask.TestChannel
  }

config :ask, Nuntium,
  base_url: "http://nuntium.com",
  guisso: [
    base_url: "http://localhost:7654",
    client_id: "NUNTIUM_CLIENT_ID",
    client_secret: "NUNTIUM_CLIENT_SECRET",
    app_id: "AN_APP_ID"
  ]

config :ask, Verboice,
  base_url: "http://verboice.com",
  guisso: [
    base_url: "http://localhost:7654",
    client_id: "VERBOICE_CLIENT_ID",
    client_secret: "VERBOICE_CLIENT_SECRET",
    app_id: "AN_APP_ID"
  ]

config :ask, Ask.Mailer,
  adapter: Ask.Swoosh.Adapters.Test

config :ask, Ask.Email,
  smtp_from_address: {:system, "SMTP_FROM_ADDRESS", "Test name <test@email>"}

# Use mock to enable/disable Guisso for the duration of a test.
config :ask, :guisso, GuissoMock

config :alto_guisso,
  base_url: "http://guisso.localhost",
  client_id: "CLIENT",
  client_secret: "SECRET"
