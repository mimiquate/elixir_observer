defmodule Toolbox.Tasks.Github do
  def run do
    Toolbox.Packages.list_packages()
    |> Enum.each(fn package ->
      %{hexpm_snapshots: [hexpm_snapshot | _]} = Toolbox.Repo.preload(package, [:hexpm_snapshots])

      links = hexpm_snapshot.data["meta"]["links"]

      if github_link = links["GitHub"] || links["Github"] || links["github"] do
        ["https:", "", "github.com", owner, repository_name | _] = String.split(github_link, "/")

        {
          :ok,
          {
            {_, 200, _},
            _headers,
            repository_data
          }
        } =
          Toolbox.Github.get_repo(owner, repository_name)

        Toolbox.Packages.create_github_snapshot(%{
          package_id: package.id,
          data: Jason.decode!(repository_data)
        })

        Process.sleep(:timer.seconds(1))
      else
        require Logger

        Logger.warning(
          "Couldn't find GitHub URL for package #{package.name}",
          metadata: %{data: inspect(hexpm_snapshot.data)}
        )

        IO.inspect(hexpm_snapshot.data)
      end
    end)
  end
end
