defmodule Toolbox.Tasks.GitHub do
  require Logger

  alias Toolbox.Github
  alias Toolbox.Packages

  def run(package, github_link) do
    with %{"owner" => owner, "repo" => repository_name} <- Github.parse_link(github_link),
         {:ok, %{status: 200, body: repository_data}} <- Github.get_repo(owner, repository_name),
         {:ok, %{status: 200, body: activity_data}} <-
           Github.get_activity_and_changelog(owner, repository_name) do
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
    else
      nil ->
        Logger.warning("COULDN'T PARSE github link #{github_link}")
        nil

      {:ok, %{status: 404}} ->
        Logger.warning("GITHUB REPO for #{github_link} NOT FOUND")
        Packages.delete_github_snapshots(package)
        nil

      {:ok, %{status: server_error}} when server_error in 500..599 ->
        {:error, "failed to fetch github data #{github_link} with status #{server_error}"}
    end
  end
end
