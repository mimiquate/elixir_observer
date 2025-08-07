defmodule ToolboxWeb.PackageLive do
  use ToolboxWeb, :live_view

  require Logger

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
  import ToolboxWeb.Components.Icons.PathIcon
  import ToolboxWeb.Components.Icons.InspectIcon
  import ToolboxWeb.Components.Icons.BookmarkIcon

  alias ToolboxWeb.Components.PackageOwners

  defmodule HexpmVersionNotFoundError do
    defexception [:message, plug_status: 404]
  end

  def mount(%{"name" => name}, _session, socket) do
    Logger.metadata(
      tower: %{
        package_name: name,
        user_agent: get_connect_info(socket, :user_agent)
      }
    )

    package = Toolbox.Packages.get_package_by_name!(name)

    github =
      if s = package.latest_github_snapshot do
        %{
          data: s.data,
          activity: s.activity,
          sync_at: s.updated_at
        }
      else
        %{
          data: nil,
          activity: nil,
          sync_at: nil
        }
      end

    hexpm_data = package.latest_hexpm_snapshot.data
    versions = versions(hexpm_data)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Toolbox.PubSub, "package_live:#{name}")
      update_owners_if_oudated(package)
      update_latest_stable_version_data_if_outdated(package)
      update_activity_if_outdated(package, github.sync_at)
    end

    related_packages =
      Toolbox.Packages.list_packages_from_category(package.category, 5)
      |> Enum.reject(&(&1.name == name))
      |> Enum.slice(0, 4)

    related_packages_count =
      if package.category do
        Toolbox.Packages.category_count(package.category)
      else
        0
      end

    {
      :ok,
      assign(
        socket,
        page_title: package.name,
        related_packages: related_packages,
        related_packages_count: related_packages_count,
        package: %{
          name: package.name,
          category: package.category,
          description: package.description,
          owners_sync_at: package.hexpm_owners_sync_at,
          owners: package.hexpm_owners,
          recent_downloads: hexpm_data["downloads"]["recent"],
          versions: versions,
          latest_version_at: hd(hexpm_data["releases"])["inserted_at"],
          latest_stable_version: hexpm_data["latest_stable_version"],
          latest_stable_version_data: package.hexpm_latest_stable_version_data,
          html_url: hexpm_data["html_url"],
          changelog_url: changelog_url(hexpm_data, github.data),
          docs_html_url: hexpm_data["docs_html_url"],
          hexpm_created_at: hexpm_data["inserted_at"],
          github_repo_url: github.data["html_url"],
          github_fullname: github.data["full_name"],
          stargazers_count: github.data["stargazers_count"],
          activity: github.activity,
          github_sync_at: github.sync_at
        }
      )
    }
  end

  def handle_params(params, _uri, socket) do
    package = socket.assigns.package
    version = params["version"] || package.latest_stable_version
    versions = Enum.map(package.versions, & &1.version)

    if version not in versions do
      raise HexpmVersionNotFoundError, "#{version} not found for #{package.name}"
    end

    version_data = version(package, version)

    requirements_description = requirements_description(version_data)

    {:noreply,
     assign(socket, %{
       current_version: version,
       requirements_description: requirements_description,
       version: version_data
     })}
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

  def handle_info(%{action: :refresh_owners, owners: owners, owners_sync_at: sync_at}, socket) do
    p = %{socket.assigns.package | owners: owners, owners_sync_at: sync_at}

    {:noreply, assign(socket, package: p)}
  end

  def handle_info(
        %{action: :refresh_latest_stable_version, latest_stable_version_data: data},
        socket
      ) do
    p = %{socket.assigns.package | latest_stable_version_data: data}
    requirements_description = requirements_description(data)

    {:noreply,
     assign(socket, package: p, version: data, requirements_description: requirements_description)}
  end

  def handle_info(%{action: :refresh_activity, activity: activity}, socket) do
    p = %{socket.assigns.package | activity: activity}

    {:noreply, assign(socket, package: p)}
  end

  def handle_info({:hide_dropdown, component_id}, socket) do
    send_update(ToolboxWeb.SearchFieldComponent, id: component_id.cid, show_dropdown: false)
    {:noreply, socket}
  end

  def update_owners_if_oudated(package) do
    sync_at = package.hexpm_owners_sync_at

    if !sync_at or DateTime.before?(DateTime.add(sync_at, 7, :day), DateTime.utc_now()) do
      %{action: :get_package_owners, name: package.name}
      |> Toolbox.Workers.HexpmWorker.new()
      |> Oban.insert()
    end
  end

  def update_latest_stable_version_data_if_outdated(package) do
    latest_stable_version = package.latest_hexpm_snapshot.data["latest_stable_version"]
    latest_stable_version_data = package.hexpm_latest_stable_version_data

    if !latest_stable_version_data or
         latest_stable_version_data.version != latest_stable_version do
      %{action: :get_latest_stable_version, name: package.name, version: latest_stable_version}
      |> Toolbox.Workers.HexpmWorker.new()
      |> Oban.insert()
    end
  end

  def update_activity_if_outdated(package, sync_at) do
    if !sync_at or DateTime.before?(DateTime.add(sync_at, 1, :hour), DateTime.utc_now()) do
      %{action: :get_activity, name: package.name}
      |> Toolbox.Workers.SCMWorker.new()
      |> Oban.insert()
    end
  end

  defp versions(hexpm_data) do
    hexpm_data["releases"]
    |> Enum.map(fn release ->
      version = release["version"]

      %{
        version: version,
        is_retired?: !!hexpm_data["retirements"][version]
      }
    end)
  end

  defp version(%{latest_stable_version_data: nil}, _version) do
    nil
  end

  defp version(%{latest_stable_version_data: %{version: version} = lsvd}, version) do
    lsvd
  end

  defp version(%{name: name}, version) do
    case Toolbox.Hexpm.get_package_version(name, version) do
      {:ok, {{_, 200, _}, _headers, version_data}} ->
        attrs =
          version_data
          |> to_string()
          |> JSON.decode!()
          |> Toolbox.Package.HexpmVersion.build_version_from_api_response()

        {:ok, data} =
          Toolbox.Package.HexpmVersion.changeset(
            %Toolbox.Package.HexpmVersion{},
            attrs
          )
          |> Ecto.Changeset.apply_action(:insert)

        data

      {:ok, {{_, status, _}, _headers, _version_data}} when status in [400, 404, 429] ->
        Logger.warning("Unable to fetch hexpm version for #{name} version #{version}")

        nil
    end
  end

  defp requirements_description(nil), do: %{}

  defp requirements_description(version_data) do
    (version_data.required ++ version_data.optional)
    |> Enum.map(fn %{name: name} -> name end)
    |> Toolbox.Packages.get_packages_by_name()
    |> Enum.into(%{}, fn p -> {p.name, p.description} end)
  end

  defp changelog_url(hexpm_data, github_data) do
    links = hexpm_data["meta"]["links"]

    hex_changelog_url = links["Changelog"] || links["CHANGELOG"]

    cond do
      is_binary(hex_changelog_url) ->
        hex_changelog_url

      github_data["has_changelog"] ->
        "#{github_data["html_url"]}/blob/-/CHANGELOG.md"

      true ->
        nil
    end
  end

  defp source_url(name, version) do
    "https://preview.hex.pm/preview/#{name}/#{version}"
  end
end
