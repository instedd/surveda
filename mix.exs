defmodule Ask.Mixfile do
  use Mix.Project

  def project do
    [app: :ask,
     build_path: "/_build",
     deps_path: "/deps",
     version: "0.31.0",
     elixir: "~> 1.8",
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
        :oauth2,
        :timex,
        :sentry,
        :prometheus_phoenix,
        :prometheus_plugs
      ],
      extra_applications: [
        :myxql,
        :coherence
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
      {:phoenix, "~> 1.4.0"},
      #{:plug, "~> 1.8"},        # held until ... ?
      #{:plug_crypto, "~> 1.1.1"}, # held until Phoenix 1.5
      {:plug_cowboy, "~> 2.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.7"},
      {:myxql, ">= 0.0.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.2.0", only: :dev},

      {:gettext, "~> 0.14"},
      {:ex_machina, "~> 2.0", only: :test},
      {:csv, "~> 1.4.2"},
      {:oauth2, "~> 0.7.0"},
      {:mutex, "~> 1.1.3"},
      {:mox, "~> 0.5", only: :test},
      {:timex, "~> 3.6.0"},
      {:sentry, "~> 7.0"},
      {:hackney, "~> 1.0"},
      {:ex_json_schema, "~> 0.5.2"},
      {:deep_merge, "~> 0.1.0"},
      {:coherence, github: "smpallen99/coherence", branch: "master", override: true}, # "~> 0.6"
      {:gen_smtp, "~> 0.11"},
      {:xml_builder, "~> 0.0.9"}, # TODO: update to ~> 2.0
      {:language_names, "~> 0.1.0"},
      {:prometheus_phoenix, "~> 1.0"},
      {:simetric, "~> 0.1.0"},
      {:prometheus_plugs, "~> 1.1"},
      {:alto_guisso, github: "instedd/alto_guisso_ex"},
      {:pp, "~> 0.1.0", only: [:dev, :test]},
      {:bypass, "~> 2.0", only: :test},
      {:trailing_format_plug, "~> 0.0.7"},
      {:gen_stage, "~> 0.14"},
      {:zstream, "~> 0.2.0"},

      {:jason, "~> 1.0"}, # required by Phoenix
      {:poison, "~> 3.1"}, # until we migrate Surveda to Jason

      #{:telemetry, "~> 0.4.3"},

      # held back because of warnings & errors with newer versions
      {:swoosh, "~> 0.17.0"},

      # held until release of https://github.com/elixir-ecto/myxql/commit/893234cc97df9be3b764eba6e1706dd6dd6c3e9b
      {:db_connection, "< 2.4.1"}
   ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.load", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.migrate": ["ecto.migrate", "ask.ecto_dump"],
      "ecto.rollback": ["ecto.rollback", "ask.ecto_dump"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
    ]
  end
end
