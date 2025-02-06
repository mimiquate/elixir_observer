defmodule Toolbox.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Supervisor.start_link(
      [
        ToolboxWeb.Telemetry,
        Toolbox.Repo,
        {DNSCluster, query: Application.get_env(:toolbox, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Toolbox.PubSub},
        ToolboxWeb.Endpoint,
        Toolbox.PackagesFetcher
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
