defmodule ElixirToolbox.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ElixirToolboxWeb.Telemetry,
      ElixirToolbox.Repo,
      {DNSCluster, query: Application.get_env(:elixir_toolbox, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ElixirToolbox.PubSub},
      # Start a worker by calling: ElixirToolbox.Worker.start_link(arg)
      # {ElixirToolbox.Worker, arg},
      # Start to serve requests, typically the last entry
      ElixirToolboxWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirToolbox.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ElixirToolboxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
