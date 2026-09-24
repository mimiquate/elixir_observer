defmodule Toolbox.Workers.HexpmCleanupWorker do
  use Oban.Worker, queue: :hexpm, max_attempts: 3

  require Logger

  import Ecto.Query

  @impl Oban.Worker
  def perform(%Oban.Job{meta: %{"cron" => true}}) do
    case last_completed_sync_at() do
      nil ->
        :ok

      %Oban.Job{inserted_at: last_sync_at} ->
        last_sync_at
        |> Toolbox.Packages.list_packages_not_synced_since()
        |> Enum.map(&Toolbox.Workers.HexpmCleanupWorker.new/1)
        |> Enum.chunk_every(500)
        |> Enum.each(&Oban.insert_all/1)

        :ok
    end
  end

  def perform(%Oban.Job{args: %{"id" => id, "name" => name}}) do
    with {:ok, :missing} <- check_package_on_hexpm(name),
         {:ok, _package} <- Toolbox.Packages.delete_package(%Toolbox.Package{id: id}) do
      Logger.warning("Deleted package #{name}, no longer available on hexpm")

      :ok
    else
      {:skip, reason} ->
        Logger.warning(reason)

        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp last_completed_sync_at do
    from(j in Oban.Job,
      where: j.worker == ^Oban.Worker.to_string(Toolbox.Workers.HexpmWorker),
      where: j.state == "completed",
      where: fragment("? @> ?", j.meta, ^%{"cron" => true}),
      order_by: [desc: j.inserted_at],
      limit: 1
    )
    |> Toolbox.Repo.one()
  end

  defp check_package_on_hexpm(name) do
    case Toolbox.Hexpm.get_package(name) do
      {:ok, %{status: 404}} ->
        {:ok, :missing}

      {:ok, %{status: 200}} ->
        {:skip, "package #{name} still exists on hexpm, skipping deletion"}

      {:ok, %{status: server_error}} when server_error in 500..599 ->
        {:error, "failed to check hexpm package #{name} with status #{server_error}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
