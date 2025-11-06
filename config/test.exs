import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :toolbox, Toolbox.Repo,
  username: "elixir_toolbox",
  password: "elixir_toolbox",
  hostname: "localhost",
  database: "elixir_toolbox_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :toolbox, ToolboxWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "n97pFWhp6ucf5DQFj4PD6Lj+Ty2JalCUyHsOTXqe62Lp+sjUqKtp6kElZPQKmltC",
  server: true

# Print only warnings and errors during test
config :logger, :default_handler, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :toolbox, Oban, testing: :manual

config :opentelemetry, traces_exporter: :none

config :toolbox,
  github_authorization_token: "123",
  github_oauth_client_id: "test_client_id",
  github_oauth_client_secret: "test_client_secret"

config :toolbox, :github_auth,
  oauth_host: Toolbox.Auth.Github.OAuthTestHost,
  api_host: Toolbox.Auth.Github.APITestHost

config :wallaby,
  otp_app: :toolbox,
  chromedriver: [
    # Attempt to fix https://github.com/elixir-wallaby/wallaby/issues/787
    binary: ""
  ]

config :toolbox, Toolbox.CommunityResources,
  path:
    Path.join([
      "..",
      "..",
      "..",
      "..",
      "test",
      "support",
      "community_resources",
      "*.json"
    ])

config :toolbox, Toolbox.Cache, adapter: Nebulex.Adapters.Nil
