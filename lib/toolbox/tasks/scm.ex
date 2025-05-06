defmodule Toolbox.Tasks.SCM do
  require Logger

  def run(_args \\ [])

  def run([]) do
    Toolbox.Packages.list_packages_names()
    |> run()
  end

  def run(names) when is_list(names) do
    names
    |> Stream.map(&Toolbox.Packages.get_package_by_name(&1))
    |> Stream.each(&run/1)
    |> Stream.run()
  end

  def run(%Toolbox.Package{} = package) do
    hexpm_snapshot = package.latest_hexpm_snapshot

    links = hexpm_snapshot.data["meta"]["links"]

    cond do
      github_link = links["GitHub"] || links["Github"] || links["github"] ->
        with {:ok, data} <- Toolbox.Tasks.GitHub.run(github_link) do
          Toolbox.Packages.create_github_snapshot(%{
            package_id: package.id,
            data: Jason.decode!(data)
          })
        end

      gitlab_link = links["GitLab"] || links["Gitlab"] || links["gitlab"] ->
        Toolbox.Tasks.GitLab.run(gitlab_link)

      repo_link = links["Repository"] ->
        # TODO: Improve this to also detect GitLab based on the URL
        with {:ok, data} <- Toolbox.Tasks.GitHub.run(repo_link) do
          Toolbox.Packages.create_github_snapshot(%{
            package_id: package.id,
            data: Jason.decode!(data)
          })
        end

      true ->
        Logger.warning(
          "Couldn't find SCM URL for package #{package.name}",
          metadata: %{data: inspect(hexpm_snapshot.data)}
        )

        IO.inspect(hexpm_snapshot.data)
    end

    Process.sleep(:timer.seconds(1))
  end
end
