defmodule Toolbox.Tasks.GitLab do
  require Logger

  def run(link) do
    Regex.named_captures(
      ~r/^https?:\/\/(?:www\.)?gitlab.com\/(?<owner>[^\/]*)\/(?<repo>[^\/\n]*)/,
      link
    )
    |> case do
      nil ->
        Logger.warning("COULDN'T PARSE GitLab link #{link}")

        {:error, :parse_error}

      %{"owner" => owner, "repo" => repository_name} ->
        Toolbox.GitLab.get_repo(owner, repository_name)
        |> case do
          {
            :ok,
            {
              {_, 404, _},
              _headers,
              _data
            }
          } ->
            Logger.warning("GitLab REPO for #{link} NOT FOUND")

            {:error, :not_found}

          {
            :ok,
            {
              {_, 200, _},
              _headers,
              repository_data
            }
          } ->
            {:ok, repository_data}
        end
    end
  end
end
