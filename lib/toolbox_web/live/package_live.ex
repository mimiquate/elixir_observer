defmodule ToolboxWeb.PackageLive do
  use ToolboxWeb, :live_view

  @ignored_topics ["elixir"]

  def mount(%{"name" => name}, _session, socket) do
    Logger.metadata(package: %{name: name})

    package = Toolbox.Packages.get_package_by_name(name)
    hexpm_data = Toolbox.Packages.last_hexpm_snapshot(package).data

    github_data =
      with %{} = s <- Toolbox.Packages.last_github_snapshot(package) do
        s.data
      end

    versions = versions(hexpm_data)
    version = hexpm_data["latest_stable_version"]

    {
      :ok,
      assign(
        socket,
        page_title: package.name,
        package: %{
          name: package.name,
          description: hexpm_data["meta"]["description"],
          owners: owners(name),
          recent_downloads: hexpm_data["downloads"]["recent"],
          versions: versions,
          latest_version_at: hd(hexpm_data["releases"])["inserted_at"],
          latest_stable_version: version,
          html_url: hexpm_data["html_url"],
          changelog_url: changelog_url(hexpm_data),
          docs_html_url: hexpm_data["docs_html_url"],
          github_repo_url: github_data["html_url"],
          stargazers_count: github_data["stargazers_count"],
          topics: (github_data["topics"] || []) -- @ignored_topics,
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

  defp owners(package_name) do
    {
      :ok,
      {
        {_, 200, _},
        _headers,
        owners_data
      }
    } = Toolbox.Hexpm.get_package_owners(package_name)

    Phoenix.json_library().decode!(owners_data)
  end

  defp versions(hexpm_data) do
    hexpm_data["releases"]
    |> Enum.map(fn release ->
      version = release["version"]

      {version, !!hexpm_data["retirements"][version]}
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

    {optional, required} =
      data["requirements"]
      |> Enum.map(fn {name, data} ->
        {name, Map.put(data, "description", package_description(name))}
      end)
      |> Enum.split_with(fn {_, %{"optional" => optional}} -> optional end)

    %{
      version: version,
      retirement: data["retirement"],
      elixir_requirement: data["meta"]["elixir"],
      required: required,
      optional: optional,
      published_at: data["inserted_at"],
      published_by_username: data["publisher"]["username"],
      published_by_email: data["publisher"]["email"]
    }
  end

  defp package_description(name) do
    with %Toolbox.Package{} = package <- Toolbox.Packages.get_package_by_name(name),
         %Toolbox.HexpmSnapshot{} = hexpm_snapshot <-
           Toolbox.Packages.last_hexpm_snapshot(package) do
      hexpm_snapshot.data["meta"]["description"]
    end
  end

  defp changelog_url(hexpm_data) do
    links = hexpm_data["meta"]["links"]

    links["Changelog"] || links["CHANGELOG"]
  end
end
