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
    layout: false
  ],
  pubsub_server: Toolbox.PubSub,
  live_view: [signing_salt: "pI1I5EQU"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.0",
  toolbox: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.0.17",
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

config :tower, :reporters, [TowerSlack, TowerRollbar]

config :tower_slack, otp_app: :toolbox

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
