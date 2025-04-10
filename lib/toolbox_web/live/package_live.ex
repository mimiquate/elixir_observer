defmodule ToolboxWeb.PackageLive do
  use ToolboxWeb, :live_view

  def mount(%{"name" => name}, _session, socket) do
    package = Toolbox.Packages.get_package_by_name(name)
    hexpm_data = Toolbox.Packages.last_hexpm_snapshot(package).data
    github_data = Toolbox.Packages.last_github_snapshot(package).data
    versions = versions(hexpm_data)
    version = hd(versions)

    {
      :ok,
      assign(
        socket,
        page_title: package.name,
        package: %{
          name: package.name,
          description: hexpm_data["meta"]["description"],
          recent_downloads: hexpm_data["downloads"]["recent"],
          versions: versions,
          html_url: hexpm_data["html_url"],
          docs_html_url: hexpm_data["docs_html_url"],
          github_repo_url: github_data["html_url"],
          stargazers_count: github_data["stargazers_count"],
          topics: github_data["topics"],
          hexpm_created_at: hexpm_data["inserted_at"]
        },
        version: version(package.name, version)
      )
    }
  end

  def handle_event(
        "version-change",
        %{"version" => version},
        %{assigns: %{package: %{name: name}}} = socket
      ) do
    {
      :noreply,
      assign(socket, version: version(name, version))
    }
  end

  defp versions(hexpm_data) do
    hexpm_data["releases"]
    |> Enum.map(fn release ->
      release["version"]
    end)
  end

  defp version(name, version) do
    {
      :ok,
      {
        {_, 200, _},
        _headers,
        version_data
      }
    } =
      Toolbox.Hexpm.get("packages/#{name}/releases/#{version}")

    data =
      version_data
      |> to_string()
      |> JSON.decode!()

    %{
      version: version,
      elixir_requirement: data["meta"]["elixir"],
      requirements: data["requirements"],
      published_at: data["inserted_at"],
      published_by: data["publisher"]["username"]
    }
  end
end
