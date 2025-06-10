defmodule Toolbox.Tasks.GitHub do
  require Logger

  alias Toolbox.Github
  alias Toolbox.Packages

  def run(package, github_link) do
    case do_run(github_link) do
      {:ok, data} ->
        Packages.upsert_github_snapshot(%{
          package_id: package.id,
          data: data
        })

      {:error, :not_found} ->
            # Delete the old snapshot if present
        github_snapshot = package.latest_github_snapshot

        if github_snapshot do
          Packages.delete_github_snapshot(github_snapshot)
        end

        nil

      {:error, :parse_error} ->
        nil
    end
  end

  defp do_run(github_link) do
    case Github.parse_link(github_link) do
      nil ->
        Logger.warning("COULDN'T PARSE github link #{github_link}")

        {:error, :parse_error}

      %{"owner" => owner, "repo" => repository_name} ->
        Github.get_repo(owner, repository_name)
        |> case do
          {
            :ok,
            {
              {_, 404, _},
              _headers,
              _data
            }
          } ->
            Logger.warning("GITHUB REPO for #{github_link} NOT FOUND")

            {:error, :not_found}

          {
            :ok,
            {
              {_, 200, _},
              _headers,
              repository_data
            }
          } ->
            {:ok, {{_, 200, _}, _headers, data}} =
              Github.get_activity_and_changelog(owner, repository_name)

            data = Jason.decode!(data)
            repository_data = Jason.decode!(repository_data)

            changelog = get_in(data, ["data", "repository", "changelog"])

            {
              :ok,
              repository_data
              |> Map.put("has_changelog", !!changelog)
              |> Map.put("activity", data)
            }
        end
    end
  end
end
