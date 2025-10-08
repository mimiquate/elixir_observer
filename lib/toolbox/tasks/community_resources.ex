defmodule Toolbox.Tasks.CommunityResources do
  require Logger

  alias Ecto.Multi

  def run do
    {:ok, _} =
      Multi.new()
      |> Multi.put(:data, data())
      |> Multi.all(:packages, &get_packages/1)
      |> Multi.merge(&update_packages/1)
      |> Toolbox.Repo.transact()

    IO.puts("Done.")
  end

  defp get_packages(%{data: data}) do
    package_names = Map.keys(data)

    Toolbox.Packages.list_packages_by_names(package_names, :as_query)
  end

  defp update_packages(%{packages: packages, data: data}) do
    Enum.reduce(packages, Multi.new(), fn package, updated_multi ->
      updated_multi
      |> Multi.update(
        :"update_#{package.name}",
        Toolbox.Package.community_resources_changeset(package, %{
          community_resources: data[package.name]
        })
      )
    end)
  end

  defp data do
    [Application.app_dir(:toolbox), "priv", "community_resources.json"]
    |> Path.join()
    |> File.read!()
    |> Jason.decode!()
  end
end
