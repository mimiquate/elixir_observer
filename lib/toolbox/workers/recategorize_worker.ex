defmodule Toolbox.Workers.RecategorizeWorker do
  use Oban.Worker, queue: :category, max_attempts: 10

  require Logger

  alias Toolbox.Packages

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"names" => names}}) do
    packages = Packages.get_packages_by_name(names)
    previous_category_ids = Map.new(packages, &{&1.name, category_id(&1.category)})

    case Toolbox.Tasks.Category.run(packages) do
      {:error, _reason} = error -> error
      results -> log_changes(results, previous_category_ids)
    end
  end

  defp log_changes(results, previous_category_ids) do
    for {:ok, package} <- results,
        package.category != previous_category_ids[package.name] do
      Logger.warning(
        "recategorized #{package.name}: #{category_name(previous_category_ids[package.name])} -> #{category_name(package.category)}"
      )
    end

    :ok
  end

  defp category_id(nil), do: nil
  defp category_id(category), do: category.id

  defp category_name(nil), do: "none"
  defp category_name(id), do: Packages.get_category_by_id!(id).name
end
