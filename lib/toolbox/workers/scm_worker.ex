defmodule Toolbox.Workers.SCMWorker do
  use Oban.Worker, queue: :scm

  @impl Oban.Worker
  def perform(%Oban.Job{meta: %{"cron" => true}}) do
    names = Toolbox.Packages.list_packages_names()

    for name <- names do
      Toolbox.Workers.SCMWorker.new(%{name: name})
      |> Oban.insert()
    end

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"name" => name}}) do
    Toolbox.Tasks.SCM.run(name)

    :ok
  end
end
