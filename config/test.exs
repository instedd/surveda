use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ask, Ask.Endpoint,
  http: [port: 4001],
  server: false,
  url: [host: "app.ask.dev", port: 80]

# Print only info messages during testing so
# we get an idea of log quality.
config :logger, level: :info

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
    base_url: "http://nuntium.com",
    client_id: "A_NO_SO_SECRET_CLIENT_ID",
    app_id: "AN_APP_ID"
  ]

config :ask, Verboice,
  base_url: "http://verboice.com",
  guisso: [
    base_url: "http://verboice.com",
    client_id: "A_NO_SO_SECRET_CLIENT_ID",
    app_id: "AN_APP_ID"
  ]

config :ask, Ask.Mailer,
  adapter: Swoosh.Adapters.Test
