defmodule Toolbox.Tasks.GitHub do
  require Logger

  alias Toolbox.Github
  alias Toolbox.Packages

  def run(package, github_link) do
    case Github.parse_link(github_link) do
      %{"owner" => owner, "repo" => repository_name} ->
        case Github.get_repo(owner, repository_name) do
          {:ok, {{_, 200, _}, _, repository_data}} ->
            {:ok, {{_, 200, _}, _h, activity_data}} =
              Github.get_activity_and_changelog(owner, repository_name)

            repository_data = Jason.decode!(repository_data)
            activity_data = Jason.decode!(activity_data)

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

          {:ok, {{_, 404, _}, _, _}} ->
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
