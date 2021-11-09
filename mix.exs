defmodule Ask.Mixfile do
  use Mix.Project

  def project do
    [app: :ask,
     build_path: "/_build",
     deps_path: "/deps",
     version: "0.31.0",
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
      applications: [
        :phoenix,
        :phoenix_pubsub,
        :phoenix_html,
        :cowboy,
        :logger,
        :gettext,
        :alto_guisso,
        :phoenix_ecto,
        :mariaex,
        :oauth2,
        :timex,
        :sentry,
        :coherence,
        :prometheus_phoenix,
        :prometheus_plugs
      ]
    ]
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
      {:mutex, "~> 1.1.3"},
      {:mox, "~> 0.5", only: :test},
      {:timex, "~> 3.3.0"},
      {:sentry, "~> 6.0"},
      {:hackney, "~> 1.0"},
      {:ex_json_schema, "~> 0.5.2"},
      {:deep_merge, "~> 0.1.0"},
      {:coherence, git: "https://github.com/manastech/coherence.git", branch: "v0.3.2", override: true},
      {:gen_smtp, "~> 0.11"},
      {:xml_builder, "~> 0.0.9"},
      {:language_names, "~> 0.1.0"},
      {:prometheus_phoenix, "~> 1.0"},
      {:simetric, "~> 0.1.0"},
      {:prometheus_plugs, "~> 1.1"},
      {:alto_guisso, git: "https://github.com/instedd/alto_guisso_ex.git"},
      {:pp, "~> 0.1.0", only: [:dev, :test]},
      {:bypass, "~> 0.8", only: :test},
      {:trailing_format_plug, "~> 0.0.7"},
      {:plug_cowboy, "~> 1.0"},
      {:gen_stage, "~> 0.14"},
      {:zstream, "~> 0.2.0"},

      # held back until we upgrade to Elixir 1.7+
      {:plug, "~> 1.8.0"},
      {:plug_crypto, "~> 1.1.1"},
      {:telemetry, "~> 0.4.3"},

      # held back because of warnings & errors with newer versions
      {:swoosh, "~> 0.17.0"},

      # held back until we update to OTP 21+
      {:prometheus, "~> 3.3.0"},
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
