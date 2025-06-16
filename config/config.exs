# General application configuration
# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

import Config

config :toolbox,
  ecto_repos: [Toolbox.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :toolbox, ToolboxWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ToolboxWeb.ErrorHTML, json: ToolboxWeb.ErrorJSON],
    root_layout: [html: {ToolboxWeb.Layouts, :root}, json: false],
    layout: false
  ],
  pubsub_server: Toolbox.PubSub,
  live_view: [signing_salt: "pI1I5EQU"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.2",
  toolbox: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.4",
  toolbox: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :toolbox, Toolbox.Cache,
  # Max memory size in bytes (e.g., 50MB)
  allocated_memory: 50_000_000

config :toolbox, Oban,
  engine: Oban.Engines.Basic,
  plugins: [
    # Prune jobs after 14 days
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 14},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 5 * * MON", Toolbox.Workers.HexpmWorker},
       {"0 6 * * MON", Toolbox.Workers.SCMWorker}
     ]}
  ],
  queues: [
    hexpm: [limit: 1],
    # Use 1 second dispatch cooldown to prevent Github's rate limit
    scm: [limit: 1, dispatch_cooldown: 1_000]
  ],
  notifier: Oban.Notifiers.PG,
  repo: Toolbox.Repo

config :opentelemetry,
  resource: [
    service: [
      name: "app",
      namespace: "Toolbox"
    ]
  ]

config :toolbox, github_base_url: "https://api.github.com"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
