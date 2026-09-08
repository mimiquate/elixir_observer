defmodule Toolbox.Workers.HexpmWorker do
  use Oban.Worker, queue: :hexpm, max_attempts: 3

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{meta: %{"cron" => true}}) do
    Toolbox.Tasks.Hexpm.run()

    :ok
  end

  def perform(%Oban.Job{args: %{"action" => "get_package_owners", "name" => name}}) do
    {:ok, %{status: 200, body: owners_data}} = Toolbox.Hexpm.get_package_owners(name)

    Toolbox.Packages.get_package_by_name(name)
    |> Toolbox.Packages.update_package_owners(%{
      hexpm_owners_sync_at: DateTime.utc_now(),
      hexpm_owners: owners_data
    })
    |> case do
      {:ok, p} ->
        Phoenix.PubSub.broadcast(
          Toolbox.PubSub,
          "package_live:#{name}",
          %{
            action: :refresh_owners,
            owners_sync_at: p.hexpm_owners_sync_at,
            owners: p.hexpm_owners
          }
        )

        {:ok, p}

      err ->
        err
    end
  end

  def perform(%Oban.Job{
        args: %{"action" => "get_latest_stable_version", "name" => name, "version" => nil}
      }) do
    Logger.warning("HEXPM package #{name} has no latest stable version, skipping version fetch")

    :ok
  end

  def perform(%Oban.Job{
        args: %{"action" => "get_latest_stable_version", "name" => name, "version" => version}
      }) do
    with {:ok, package} <- get_package_by_name(name),
         {:ok, version_data} <- get_package_version(name, version),
         {:ok, p} <-
           Toolbox.Packages.update_package_latest_stable_version(package, %{
             hexpm_latest_stable_version_data: version_data
           }) do
      Phoenix.PubSub.broadcast(
        Toolbox.PubSub,
        "package_live:#{name}",
        %{
          action: :refresh_latest_stable_version,
          latest_stable_version_data: p.hexpm_latest_stable_version_data
        }
      )

      {:ok, p}
    else
      {:skip, reason} ->
        Logger.warning(reason)

        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_package_by_name(name) do
    case Toolbox.Packages.get_package_by_name(name) do
      %Toolbox.Package{} = package -> {:ok, package}
      nil -> {:skip, "package #{name} not found"}
    end
  end

  defp get_package_version(name, version) do
    case Toolbox.Hexpm.get_package_version(name, version) do
      {:ok, %{status: 200, body: version_data}} ->
        {:ok, Toolbox.Package.HexpmVersion.build_version_from_api_response(version_data)}

      {:ok, %{status: status}} when status in [400, 404, 429] ->
        {:skip, "Unable to fetch hexpm version for #{name} version #{version}"}

      {:ok, %{status: status}} ->
        {:error, "failed to fetch hexpm version #{version} for #{name} with status #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
