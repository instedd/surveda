defmodule Ask.Mixfile do
  use Mix.Project

  def project do
    [app: :ask,
     version: "0.8.0",
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     consolidate_protocols: Mix.env != :test,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Ask, []},
     applications: [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger, :gettext,
                    :phoenix_ecto, :mariaex, :oauth2, :timex_ecto, :sentry, :appsignal, :coherence]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.2.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.0"},
      {:mariaex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.6"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11.0"},
      {:cowboy, "~> 1.0"},
      {:ex_machina, "~> 1.0", only: :test},
      {:csv, "~> 1.4.2"},
      {:oauth2, "~> 0.7.0"},
      {:mock, "~> 0.1.1", only: :test},
      {:timex, "~> 3.0", override: true},
      {:timex_ecto, "~> 3.0", override: true},
      {:sentry, "~> 1.0"},
      {:hackney, "~> 1.0"},
      {:tributary, "~> 0.2.1"},
      {:ex_json_schema, "~> 0.5.2"},
      {:mailgun, git: "https://github.com/chrismccord/mailgun.git", override: true},
      {:appsignal, "~> 0.9.2"},
      {:deep_merge, "~> 0.1.0"},
      {:coherence, git: "https://github.com/manastech/coherence.git", branch: "v0.3.2"},
      {:gen_smtp, "~> 0.11"},
      {:xml_builder, "~> 0.0.9"}
   ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
