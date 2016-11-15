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

config :addict,
  password_hasher: Ask.Base64Hasher

config :ask, :channel,
  providers: %{
    "test" => Ask.TestChannel
  }
