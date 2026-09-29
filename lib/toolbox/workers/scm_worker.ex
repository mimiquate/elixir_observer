defmodule Toolbox.Workers.SCMWorker do
  use Oban.Worker, queue: :scm, max_attempts: 3

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{meta: %{"cron" => true}}) do
    names = Toolbox.Packages.list_packages_names()

    names
    |> Enum.map(&Toolbox.Workers.SCMWorker.new(%{name: &1}))
    |> Enum.chunk_every(500)
    |> Enum.map(&Oban.insert_all/1)

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"action" => "get_activity", "name" => name}}) do
    package = Toolbox.Packages.get_package_by_name(name)

    with {:ok, github_snapshot} = result <- Toolbox.Tasks.SCM.run(package) do
      Phoenix.PubSub.broadcast(
        Toolbox.PubSub,
        "package_live:#{name}",
        %{
          action: :refresh_activity,
          activity: github_snapshot.activity
        }
      )

      result
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"name" => name}}) do
    case get_package_by_name(name) do
      {:ok, package} ->
        Toolbox.Tasks.SCM.run(package)

        :ok

      {:skip, reason} ->
        Logger.warning(reason)
        :ok
    end
  end

  defp get_package_by_name(name) do
    case Toolbox.Packages.get_package_by_name(name) do
      %Toolbox.Package{} = package -> {:ok, package}
      nil -> {:skip, "package #{name} not found"}
    end
  end
end
