defmodule Toolbox.Workers.CategoryWorker do
  use Oban.Worker, queue: :category, max_attempts: 10

  require Logger

  alias Toolbox.Packages

  @impl Oban.Worker
  def perform(%Oban.Job{meta: %{"cron" => true}}) do
    Packages.list_packages_names_with_no_category()
    |> Enum.map(&Toolbox.Workers.CategoryWorker.new(%{name: &1}))
    |> Enum.chunk_every(500)
    |> Enum.each(&Oban.insert_all/1)
  end

  def perform(%Oban.Job{args: %{"name" => name}}) do
    case get_package_by_name(name) do
      {:ok, package} ->
        categorize(package)

      {:skip, reason} ->
        Logger.warning(reason)

        {:cancel, reason}
    end
  end

  defp get_package_by_name(name) do
    case Packages.get_package_by_name(name) do
      %Toolbox.Package{} = package -> {:ok, package}
      nil -> {:skip, "package #{name} not found"}
    end
  end

  defp categorize(package) do
    case Toolbox.Tasks.Category.run(package) do
      {:ok, _package} -> :ok
      {:error, _reason} = error -> error
    end
  end
end
