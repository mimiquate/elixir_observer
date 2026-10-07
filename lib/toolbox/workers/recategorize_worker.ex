defmodule Toolbox.Workers.RecategorizeWorker do
  use Oban.Worker, queue: :category, max_attempts: 10

  require Logger

  alias Toolbox.Packages

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"name" => name}}) do
    case get_package_by_name(name) do
      {:ok, package} ->
        recategorize(package)

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

  defp recategorize(package) do
    previous_category_id = category_id(package.category)

    case Toolbox.Tasks.Category.run(package) do
      {:ok, updated} ->
        log_change(updated, previous_category_id)
        :ok

      {:error, _reason} = error ->
        error
    end
  end

  defp log_change(package, previous_category_id) do
    new_category_id = category_id(package.category)

    if new_category_id != previous_category_id do
      Logger.warning(
        "recategorized #{package.name}: #{category_name(previous_category_id)} -> #{category_name(new_category_id)}"
      )
    end
  end

  # Updated packages hold the category id, loaded ones hold the struct.
  defp category_id(nil), do: nil
  defp category_id(id) when is_integer(id), do: id
  defp category_id(%Toolbox.Category{id: id}), do: id

  defp category_name(nil), do: "none"
  defp category_name(id), do: Toolbox.Category.find_by_id(id).name
end
