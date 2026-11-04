defmodule Toolbox.Workers.CategoryWorker do
  use Oban.Worker, queue: :category, max_attempts: 5

  require Logger

  alias Toolbox.Packages

  @impl Oban.Worker
  def perform(%Oban.Job{meta: %{"cron" => true}}) do
    Packages.list_packages_names_with_no_category()
    |> enqueue(log_on_update: false)
  end

  def perform(%Oban.Job{args: %{"name" => name, "log_on_update" => log_on_update}}) do
    with {:ok, package} <- get_package_by_name(name),
         :ok <- Toolbox.Tasks.Category.categorize(package, log_on_update: log_on_update) do
      :ok
    else
      {:skip, reason} ->
        Logger.warning(reason)

        {:cancel, reason}

      other ->
        other
    end
  end

  def recategorize do
    Packages.list_packages_names()
    |> enqueue(log_on_update: true)
  end

  defp enqueue(names, log_on_update: log_on_update) do
    names
    |> Enum.map(&new(%{name: &1, log_on_update: log_on_update}))
    |> Enum.chunk_every(500)
    |> Enum.each(&Oban.insert_all/1)
  end

  defp get_package_by_name(name) do
    case Packages.get_package_by_name(name) do
      %Toolbox.Package{} = package -> {:ok, package}
      nil -> {:skip, "package #{name} not found"}
    end
  end
end
