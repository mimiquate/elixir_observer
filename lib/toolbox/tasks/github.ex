defmodule Toolbox.Tasks.GitHub do
  require Logger

  alias Toolbox.Github
  alias Toolbox.Packages

  def run(package, github_link) do
    case Github.parse_link(github_link) do
      %{"owner" => owner, "repo" => repository_name} ->
        case Github.get_repo(owner, repository_name) do
          {:ok, %{status: 200, body: repository_data}} ->
            {:ok, %{status: 200, body: activity_data}} =
              Github.get_activity_and_changelog(owner, repository_name)

            changelog = get_in(activity_data, ["data", "repository", "changelog"])

            repository_data =
              repository_data
              |> Map.put("has_changelog", !!changelog)

            activity = Toolbox.GithubSnapshot.Activity.build_from_api_response(activity_data)

            Toolbox.Packages.upsert_github_snapshot(%{
              package_id: package.id,
              activity: activity,
              data: repository_data
            })

          {:ok, %{status: 404}} ->
            Logger.warning("GITHUB REPO for #{github_link} NOT FOUND")
            Packages.delete_github_snapshots(package)
            nil
        end

      nil ->
        Logger.warning("COULDN'T PARSE github link #{github_link}")
        nil
    end
  end
end
