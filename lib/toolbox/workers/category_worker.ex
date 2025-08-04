defmodule Toolbox.Workers.CategoryWorker do
  use Oban.Worker, queue: :category, max_attempts: 10

  @impl Oban.Worker
  def perform(%Oban.Job{meta: %{"cron" => true}}) do
    names = Toolbox.Packages.list_packages_names_with_no_category()

    names
    |> Enum.chunk_every(300)
    |> Enum.map(&Toolbox.Workers.CategoryWorker.new(%{names: &1}))
    |> Enum.chunk_every(500)
    |> Enum.map(&Oban.insert_all/1)

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"names" => names}}) do
    names
    |> Toolbox.Packages.get_packages_by_name()
    |> Toolbox.Tasks.Category.run()

    :ok
  end
end
