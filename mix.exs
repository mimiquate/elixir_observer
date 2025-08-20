defmodule Toolbox.MixProject do
  use Mix.Project

  def project do
    [
      app: :toolbox,
      version: "0.1.0",
      elixir: "~> 1.18.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        toolbox: [
          applications: [opentelemetry: :temporary],
          include_executables_for: [:unix]
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Toolbox.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bandit, "~> 1.5"},
      {:dns_cluster, "~> 0.2.0"},
      {:ecto_sql, "~> 3.10"},
      {:esbuild, "~> 0.10.0", runtime: Mix.env() == :dev},
      {:gettext, "~> 0.20"},
      {
        :heroicons,
        github: "tailwindlabs/heroicons",
        tag: "v2.2.0",
        sparse: "optimized",
        app: false,
        compile: false,
        depth: 1
      },
      {:jason, "~> 1.2"},
      {:phoenix, "~> 1.8.0"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_live_view, "~> 1.0"},
      {:postgrex, "~> 0.21.1"},
      {:tailwind, "~> 0.3.0", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:number, "~> 1.0"},
      {:nebulex, "~> 3.0.0-rc.1"},
      {:nebulex_local, "~> 3.0.0-rc.1"},
      {:decorator, "~> 1.4"},
      {:oban, "~> 2.19"},
      {:oban_web, "~> 2.11"},
      {:logger_json, "~> 7.0"},
      {:pgvector, "~> 0.3.0"},

      # OpenTelemetry
      {:opentelemetry, "~> 1.3"},
      {:opentelemetry_api, "~> 1.2"},
      {:opentelemetry_exporter, "~> 1.6"},
      {:opentelemetry_bandit, "~> 0.2.0"},
      {:opentelemetry_phoenix, "~> 2.0"},
      {:opentelemetry_ecto, "~> 1.2"},
      # XXX https://github.com/open-telemetry/opentelemetry-erlang-contrib/pull/436
      {:opentelemetry_semantic_conventions, "~> 1.27", override: true},

      # Dev and Prod
      {:tower_rollbar, "~> 0.6.3", only: [:dev, :prod]},
      {:tower_slack, "~> 0.6.0", only: [:dev, :prod]},

      # Dev
      {:dotenv_parser, "~> 2.0", only: :dev},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:live_debugger, "~> 0.3.1", only: :dev},

      # Test
      {:floki, "~> 0.38.0", only: :test},
      {:wallaby, "~> 0.30.9", runtime: false, only: :test},
      {:test_server, "~> 0.1.20", only: [:test]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind toolbox", "esbuild toolbox"],
      "assets.deploy": [
        "tailwind toolbox --minify",
        "esbuild toolbox --minify",
        "phx.digest"
      ]
    ]
  end
end
