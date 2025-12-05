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

config :toolbox, Toolbox.Repo, types: Toolbox.PostgrexTypes

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
  version: "0.25.10",
  toolbox: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.13",
  toolbox: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :toolbox, Toolbox.Cache,
  adapter: Nebulex.Adapters.Local,
  # Max memory size in bytes (e.g., 100MB)
  allocated_memory: 100_000_000

config :toolbox, Oban,
  engine: Oban.Engines.Basic,
  plugins: [
    # Prune jobs after 14 days
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 14},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 5 * * SUN", Toolbox.Workers.HexpmWorker},
       {"0 6 * * SUN", Toolbox.Workers.SCMWorker},
       {"0 7 * * SUN", Toolbox.Workers.CategoryWorker}
     ]}
  ],
  queues: [
    hexpm: [limit: 1],
    category: [limit: 1],
    # Use 750ms second dispatch cooldown to prevent Github's rate limit
    # We are doing 2 request in each job
    # 1 to the REST API, 1 to the GraphQL API
    # Even if the request is instantaneous we will do at most (1/0.750)*3600 = 4800 < 5000
    scm: [limit: 1, dispatch_cooldown: 750]
  ],
  notifier: Oban.Notifiers.PG,
  repo: Toolbox.Repo

config :opentelemetry,
  sampler: {Toolbox.OtelSampler, %{}},
  resource: [
    service: [
      name: "app",
      namespace: "Toolbox"
    ]
  ]

config :toolbox,
  gemini_base_url: "https://generativelanguage.googleapis.com"

config :toolbox, ToolboxWeb.PlugAttack, limit: 100

config :toolbox, Toolbox.CommunityResources,
  path: Path.join(["priv", "community_resources", "*.json"])

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
