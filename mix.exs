defmodule Ask.Mixfile do
  use Mix.Project

  def project do
    [app: :ask,
     version: "0.14.2",
     elixir: "~> 1.5",
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
     applications: [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger, :gettext, :alto_guisso,
                    :phoenix_ecto, :mariaex, :oauth2, :timex_ecto, :sentry, :coherence, :prometheus_phoenix, :prometheus_plugs]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.0"},
      {:mariaex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.10.3"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.13.1"},
      {:cowboy, "~> 1.1.2"},
      {:ex_machina, "~> 1.0", only: :test},
      {:csv, "~> 1.4.2"},
      {:oauth2, "~> 0.7.0"},
      {:mock, "~> 0.1.1", only: :test},
      {:timex, "~> 3.0", override: true},
      {:timex_ecto, "~> 3.0", override: true},
      {:sentry, "~> 5.0"},
      {:hackney, "~> 1.0"},
      {:ex_json_schema, "~> 0.5.2"},
      {:deep_merge, "~> 0.1.0"},
      {:coherence, git: "https://github.com/manastech/coherence.git", branch: "v0.3.2"},
      {:gen_smtp, "~> 0.11"},
      {:xml_builder, "~> 0.0.9"},
      {:language_names, "~> 0.1.0"},
      {:prometheus_phoenix, "~> 1.0"},
      {:prometheus_plugs, "~> 1.1"},
      {:alto_guisso, git: "https://github.com/instedd/alto_guisso_ex.git"}
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
