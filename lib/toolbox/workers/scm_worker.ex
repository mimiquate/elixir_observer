defmodule Toolbox.Workers.SCMWorker do
  use Oban.Worker, queue: :scm, max_attempts: 3

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

    case Toolbox.Tasks.SCM.run(package) do
      {:ok, github_snapshot} ->
        Phoenix.PubSub.broadcast(
          Toolbox.PubSub,
          "package_live:#{name}",
          %{
            action: :refresh_activity,
            activity: github_snapshot.activity
          }
        )

        {:ok, github_snapshot}
      res -> res
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"name" => name}}) do
    Toolbox.Tasks.SCM.run(name)

    :ok
  end
end
