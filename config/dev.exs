use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :ask, Ask.Endpoint,
  http: [port: System.get_env("HTTP_PORT") || 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false

# watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
#                   cd: Path.expand("../", __DIR__)]]

# Watch static and templates for browser reloading.
config :ask, Ask.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex)$}
    ]
  ]

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :ask, Ask.Repo,
  adapter: Ecto.Adapters.MySQL,
  username: "root",
  password: "",
  database: "ask_dev",
  hostname: System.get_env("DATABASE_HOST") || "localhost",
  pool_size: 10

config :ask, Ask.Mailer, adapter: Swoosh.Adapters.Local

config :coherence,
  email_from_name: "Surveda Dev",
  email_from_email: "myname@domain.com"

config :coherence, Ask.Coherence.Mailer, adapter: Swoosh.Adapters.Local
