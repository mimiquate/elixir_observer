defmodule ToolboxWeb.PackageLive do
  use ToolboxWeb, :live_view

  import ToolboxWeb.Components.StatsCard
  import ToolboxWeb.Components.PackageLink
  import ToolboxWeb.Components.PackageVersionSelector
  import ToolboxWeb.Components.PackageActivity, only: [package_activity: 1]

  import ToolboxWeb.Components.Icons.StarIcon
  import ToolboxWeb.Components.Icons.DownloadIcon
  import ToolboxWeb.Components.Icons.CalendarIcon
  import ToolboxWeb.Components.Icons.ChevronIcon
  import ToolboxWeb.Components.Icons.GithubIcon
  import ToolboxWeb.Components.Icons.HexIcon
  import ToolboxWeb.Components.Icons.DocIcon
  import ToolboxWeb.Components.Icons.ChangelogIcon
  import ToolboxWeb.Components.Icons.DependenciesIcon
  import ToolboxWeb.Components.Icons.ElixirIcon

  defmodule HexpmVersionNotFoundError do
    defexception [:message, plug_status: 404]
  end

  @ignored_topics ["elixir"]

  def mount(%{"name" => name}, _session, socket) do
    Logger.metadata(
      tower: %{
        package_name: name,
        user_agent: get_connect_info(socket, :user_agent)
      }
    )

    package = Toolbox.Packages.get_package_by_name!(name)
    hexpm_data = package.latest_hexpm_snapshot.data

    github_data =
      with %{} = s <- package.latest_github_snapshot do
        s.data
      end

    activity = Toolbox.Packages.get_github_activity(github_data)

    versions = versions(hexpm_data)

    {
      :ok,
      assign(
        socket,
        page_title: package.name,
        package: %{
          name: package.name,
          description: package.description,
          owners: owners(name),
          recent_downloads: hexpm_data["downloads"]["recent"],
          versions: versions,
          latest_version_at: hd(hexpm_data["releases"])["inserted_at"],
          latest_stable_version: hexpm_data["latest_stable_version"],
          html_url: hexpm_data["html_url"],
          changelog_url: changelog_url(hexpm_data),
          docs_html_url: hexpm_data["docs_html_url"],
          github_repo_url: github_data["html_url"],
          github_fullname: github_data["full_name"],
          stargazers_count: github_data["stargazers_count"],
          topics: (github_data["topics"] || []) -- @ignored_topics,
          hexpm_created_at: hexpm_data["inserted_at"],
          activity: activity
        }
      )
    }
  end

  def handle_params(params, _uri, socket) do
    %{name: name, latest_stable_version: lsv} = socket.assigns.package
    version = params["version"] || lsv

    {:noreply, assign(socket, %{version: version(name, version)})}
  end

  def handle_event(
        "version-change",
        %{"version" => version},
        %{assigns: %{package: %{name: name, latest_stable_version: lsv}}} = socket
      ) do
    if version == lsv do
      {:noreply, push_patch(socket, to: ~p"/packages/#{name}")}
    else
      {:noreply, push_patch(socket, to: ~p"/packages/#{name}/#{version}")}
    end
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
    version_data =
      case Toolbox.Hexpm.get_package_version(name, version) do
        {:ok, {{_, 200, _}, _headers, version_data}} ->
          version_data

        {:ok, {{_, status, _}, _headers, _version_data}} when status in [400, 404] ->
          raise HexpmVersionNotFoundError, "#{version} not found for #{name}"
      end

    data =
      version_data
      |> to_string()
      |> JSON.decode!()

    descriptions =
      data["requirements"]
      |> Enum.map(fn {name, _data} -> name end)
      |> Toolbox.Packages.get_packages_by_name()
      |> Enum.into(%{}, fn p -> {p.name, p.description} end)

    {optional, required} =
      data["requirements"]
      |> Enum.map(fn {name, data} ->
        {name, Map.put(data, "description", descriptions[name])}
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

  defp changelog_url(hexpm_data) do
    links = hexpm_data["meta"]["links"]

    links["Changelog"] || links["CHANGELOG"]
  end
end
