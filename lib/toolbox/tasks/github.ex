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
            {:ok, {{_, 200, _}, _headers, activity_data}} =
              Toolbox.Github.get_activity(owner, repository_name)

            activity_data = activity_data |> Jason.decode!()

            {
              :ok,
              repository_data
              |> Jason.decode!()
              |> Map.put("activity", activity_data)
            }
        end
    end
  end
end
