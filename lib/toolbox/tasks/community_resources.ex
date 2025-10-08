defmodule Toolbox.Tasks.CommunityResources do
  require Logger

  def run do
    {:ok, _} = Toolbox.Packages.bulk_update_community_resources(data())

    Logger.info("Done.")
  end

  defp data do
    [Application.app_dir(:toolbox), "priv", "community_resources.json"]
    |> Path.join()
    |> File.read!()
    |> Jason.decode!()
  end
end
