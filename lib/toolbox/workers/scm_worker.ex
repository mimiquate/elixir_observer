defmodule Toolbox.Workers.SCMWorker do
  use Oban.Worker, queue: :scm

  @impl Oban.Worker
  def perform(%Oban.Job{meta: %{"cron" => true}}) do
    names = Toolbox.Packages.list_packages_names()

    names
    |> Enum.map(&Toolbox.Workers.SCMWorker.new(%{name: &1}))
    |> Oban.insert_all()

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"name" => name}}) do
    Toolbox.Tasks.SCM.run(name)

    :ok
  end
end
