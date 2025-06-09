defmodule Toolbox.Workers.HexpmWorker do
  use Oban.Worker, queue: :hexpm, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{meta: %{"cron" => true}}) do
    Toolbox.Tasks.Hexpm.run()

    :ok
  end

  def perform(%Oban.Job{args: %{"action" => "get_package_owners", "name" => name}}) do
    {
      :ok,
      {
        {_, 200, _},
        _headers,
        owners_data
      }
    } = Toolbox.Hexpm.get_package_owners(name)

    owners_data = Phoenix.json_library().decode!(owners_data)

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
        args: %{"action" => "get_latest_stable_version", "name" => name, "version" => version}
      }) do
    {
      :ok,
      {
        {_, 200, _},
        _headers,
        version_data
      }
    } = Toolbox.Hexpm.get_package_version(name, version)

    version_data = Phoenix.json_library().decode!(version_data)

    Toolbox.Packages.get_package_by_name(name)
    |> Toolbox.Packages.update_package_latest_stable_version(%{
      hexpm_latest_stable_version_data:
        Toolbox.Package.HexpmVersion.build_version_from_api_response(version_data)
    })
    |> case do
      {:ok, p} ->
        Phoenix.PubSub.broadcast(
          Toolbox.PubSub,
          "package_live:#{name}",
          %{
            action: :refresh_latest_stable_version,
            latest_stable_version_data: p.hexpm_latest_stable_version_data
          }
        )

        {:ok, p}

      err ->
        err
    end
  end
end
