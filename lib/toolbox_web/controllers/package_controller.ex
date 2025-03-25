defmodule ToolboxWeb.PackageController do
  use ToolboxWeb, :controller

  def show(conn, %{"name" => name}) do
    render(conn, :show, package: package(name), page_title: name)
  end

  defp package(name) do
    package = Toolbox.Packages.get_package_by_name(name)
    hexpm_data = Toolbox.Packages.last_hexpm_snapshot(package).data
    github_data = Toolbox.Packages.last_github_snapshot(package).data

    IO.inspect(hexpm_data)
    [%{"version" => version} | _] = hexpm_data["releases"]

    {
      :ok,
      {
        {_, 200, _},
        _headers,
        release_data
      }
    } = Toolbox.Hexpm.get_package_release(name, version)

    release_data = Phoenix.json_library().decode!(release_data)
    IO.inspect(release_data)

    %{
      name: package.name,
      description: hexpm_data["meta"]["description"],
      recent_downloads: hexpm_data["downloads"]["recent"],
      total_downloads: hexpm_data["downloads"]["all"],
      latest_stable_version: hexpm_data["latest_stable_version"],
      html_url: hexpm_data["html_url"],
      docs_html_url: hexpm_data["docs_html_url"],
      github_repo_url: github_data["url"],
      stargazers_count: github_data["stargazers_count"],
      topics: github_data["topics"],
      release: release_data,
      github_created_at: github_data["created_at"],
      hexpm_created_at: hexpm_data["inserted_at"]
    }
  end
end
