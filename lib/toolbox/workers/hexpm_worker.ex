defmodule Toolbox.Workers.HexpmWorker do
  use Oban.Worker, queue: :hexpm, max_attempts: 3

  require Logger

  @page_size 5
  @window_days 90

  @impl Oban.Worker
  def perform(%Oban.Job{meta: %{"cron" => true}}) do
    Toolbox.Tasks.Hexpm.run()

    :ok
  end

  def perform(%Oban.Job{args: %{"action" => "get_package_owners", "name" => name}}) do
    with {:ok, package} <- get_package_by_name(name),
         {:ok, owners_data} <- get_package_owners(name),
         {:ok, p} <-
           Toolbox.Packages.update_package_owners(package, %{
             hexpm_owners_sync_at: DateTime.utc_now(),
             hexpm_owners: owners_data
           }) do
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
    else
      {:skip, reason} ->
        Logger.warning(reason)
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  def perform(%Oban.Job{
        args: %{"action" => "get_latest_stable_version", "name" => name, "version" => nil}
      }) do
    Logger.warning("Hexpm package #{name} has no latest stable version, skipping version fetch")

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

  def perform(%Oban.Job{
        args: %{"action" => "get_version_downloads", "name" => name, "offset" => offset}
      }) do
    with {:ok, package} <- get_package_by_name(name),
         {:ok, entries} <-
           fetch_version_downloads_page(name, package.latest_hexpm_snapshot.data, offset) do
      Phoenix.PubSub.broadcast(
        Toolbox.PubSub,
        "package_live:#{name}",
        %{
          action: :refresh_version_downloads,
          offset: offset,
          version_downloads: entries
        }
      )

      :ok
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

      {:ok, %{status: status}} when status in [400, 404] ->
        {:skip, "Unable to fetch hexpm version for #{name} version #{version}"}

      {:ok, %{status: server_error}} when server_error in 500..599 ->
        {:error,
         "failed to fetch hexpm version #{version} for #{name} with status #{server_error}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_package_owners(name) do
    case Toolbox.Hexpm.get_package_owners(name) do
      {:ok, %{status: 200, body: owners_data}} ->
        {:ok, owners_data}

      {:ok, %{status: status}} when status in [400, 404] ->
        {:skip, "Unable to fetch hexpm owners for #{name}"}

      {:ok, %{status: server_error}} when server_error in 500..599 ->
        {:error, "failed to fetch hexpm owners for #{name} with status #{server_error}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_version_downloads(name, version, after_date, before_date) do
    case Toolbox.Hexpm.get_package_version_downloads(name, version, after_date, before_date) do
      {:ok, %{status: 200, body: %{"downloads" => downloads}}} when is_integer(downloads) ->
        {:ok, downloads}

      {:ok, %{status: status}} when status in [400, 404] ->
        {:ok, 0}

      {:ok, %{status: server_error}} when server_error in 500..599 ->
        {:error,
         "failed to fetch hexpm downloads for #{name} version #{version} with status #{server_error}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_version_downloads_page(name, snapshot_data, offset) do
    before_date = Date.add(Date.utc_today(), -1)
    after_date = Date.add(Date.utc_today(), -@window_days)

    (snapshot_data["releases"] || [])
    |> Toolbox.Hexpm.stable_versions_desc()
    |> Enum.slice(offset, @page_size)
    |> Task.async_stream(
      fn version -> {version, get_version_downloads(name, version, after_date, before_date)} end,
      max_concurrency: @page_size,
      ordered: true,
      timeout: :infinity
    )
    |> Enum.map(fn {:ok, result} -> result end)
    |> collect_page()
  end

  defp collect_page(results) do
    Enum.reduce_while(results, {:ok, []}, fn
      {version, {:ok, downloads}}, {:ok, entries} ->
        {:cont, {:ok, entries ++ [%{version: version, downloads: downloads}]}}

      {_version, {:error, reason}}, _acc ->
        {:halt, {:error, reason}}
    end)
  end
end
