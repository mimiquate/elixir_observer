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
    with %Toolbox.Package{} = package <- Toolbox.Packages.get_package_by_name(name),
         {:ok, %{status: 200, body: version_data}} <-
           Toolbox.Hexpm.get_package_version(name, version),
         {:ok, p} <-
           Toolbox.Packages.update_package_latest_stable_version(package, %{
             hexpm_latest_stable_version_data:
               Toolbox.Package.HexpmVersion.build_version_from_api_response(version_data)
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
      nil ->
        Logger.warning("HEXPM package #{name} not found in database")

        :ok

      {:ok, %{status: status}} when status in [400, 404, 429] ->
        Logger.warning("Unable to fetch hexpm version for #{name} version #{version}")

        :ok

      {:ok, %{status: status}} ->
        {:error, "failed to fetch hexpm version #{version} for #{name} with status #{status}"}

      {:error, _reason} = error ->
        error
    end
  end
end
