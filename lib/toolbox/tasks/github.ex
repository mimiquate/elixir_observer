defmodule Toolbox.Tasks.GitHub do
  require Logger

  def run(github_link) do
    Regex.named_captures(
      ~r/^https?:\/\/(?:www\.)?github.com\/(?<owner>[^\/]*)\/(?<repo>[^\/\n]*)/,
      github_link
    )
    |> case do
      nil ->
        Logger.warning("COULDN'T PARSE github link #{github_link}")

        {:error, :parse_error}

      %{"owner" => owner, "repo" => repository_name} ->
        Toolbox.Github.get_repo(owner, repository_name)
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
              Toolbox.Github.get_activity_and_changelog(owner, repository_name)

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
