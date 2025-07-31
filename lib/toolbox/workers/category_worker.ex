defmodule Toolbox.Workers.CategoryWorker do
  use Oban.Worker, queue: :category, max_attempts: 10

  @impl Oban.Worker
  def perform(%Oban.Job{meta: %{"cron" => true}}) do
    names = Toolbox.Packages.list_packages_names_with_no_category()

    names
    |> Enum.map(&Toolbox.Workers.CategoryWorker.new(%{name: &1}))
    |> Enum.chunk_every(500)
    |> Enum.map(&Oban.insert_all/1)

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"name" => name}}) do
    Toolbox.Tasks.Category.run(name)

    :ok
  end
end
