defmodule Toolbox.Tasks.Github do
  require Logger

  def run do
    Toolbox.Packages.list_packages()
    |> Enum.each(fn package ->
      %{hexpm_snapshots: [hexpm_snapshot | _]} = Toolbox.Repo.preload(package, [:hexpm_snapshots])

      links = hexpm_snapshot.data["meta"]["links"]

      if github_link = links["GitHub"] || links["Github"] || links["github"] do
        Regex.named_captures(
          ~r/^https?:\/\/(?:www\.)?github.com\/(?<owner>[^\/]*)\/(?<repo>[^\/\n]*)/,
          github_link
        )
        |> case do
          nil ->
            Logger.warning("COULDN'T PARSE github link #{github_link}")

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

              {
                :ok,
                {
                  {_, 200, _},
                  _headers,
                  repository_data
                }
              } ->
                Toolbox.Packages.create_github_snapshot(%{
                  package_id: package.id,
                  data: Jason.decode!(repository_data)
                })

                Process.sleep(:timer.seconds(1))
            end
        end
      else
        Logger.warning(
          "Couldn't find GitHub URL for package #{package.name}",
          metadata: %{data: inspect(hexpm_snapshot.data)}
        )

        IO.inspect(hexpm_snapshot.data)
      end
    end)
  end
end
