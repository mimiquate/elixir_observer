defmodule Toolbox.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    OpentelemetryBandit.setup()
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:toolbox, :repo], db_statement: :enabled)

    :telemetry.attach(
      "oban-logger",
      [:oban, :job, :exception],
      &Toolbox.ObanLogger.handle_event/4,
      []
    )

    Supervisor.start_link(
      [
        Toolbox.Cache,
        ToolboxWeb.Telemetry,
        Toolbox.Repo,
        {Oban, Application.fetch_env!(:toolbox, Oban)},
        {DNSCluster, query: Application.get_env(:toolbox, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Toolbox.PubSub},
        ToolboxWeb.Endpoint
      ],
      # See https://hexdocs.pm/elixir/Supervisor.html
      # for other strategies and supported options
      strategy: :one_for_one,
      name: Toolbox.Supervisor
    )
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ToolboxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
