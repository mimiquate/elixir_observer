defmodule Toolbox.Tasks.SCM do
  require Logger

  def run(_args \\ [])

  def run([]) do
    Toolbox.Packages.list_packages()
    |> Enum.each(&run/1)
  end

  def run(names) when is_list(names) do
    names
    |> Enum.map(&Toolbox.Packages.get_package_by_name(&1))
    |> Enum.each(&run/1)
  end

  def run(%Toolbox.Package{} = package) do
    %{hexpm_snapshots: [hexpm_snapshot | _]} = Toolbox.Repo.preload(package, [:hexpm_snapshots])

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
