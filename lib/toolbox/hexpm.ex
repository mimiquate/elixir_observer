defmodule Toolbox.Hexpm do
  use Nebulex.Caching, cache: Toolbox.Cache

  def get_page(page) do
    get("packages?sort=inserted_at&page=#{page}")
  end

  def get_package(name) do
    get("packages/#{name}")
  end

  def get(path) do
    Req.get("#{base_url()}/#{path}", headers: [{"user-agent", "toolbox"}])
  end

  @decorate cacheable(key: {:hexpm_version, name, version}, opts: [ttl: :timer.hours(24)])
  def get_package_version(name, version) do
    get("packages/#{name}/releases/#{version}")
  end

  @decorate cacheable(key: {:hexpm_owner, package_name}, opts: [ttl: :timer.hours(24)])
  def get_package_owners(package_name) do
    Req.get("#{base_url()}/packages/#{package_name}/owners", headers: [{"user-agent", "toolbox"}])
  end

  @decorate cacheable(
              key: {:hexpm_version_downloads, name, version, after_date, before_date},
              match: &cacheable_response?/1,
              opts: [ttl: :timer.hours(24)]
            )
  def get_package_version_downloads(name, version, after_date, before_date) do
    Req.get("#{base_url()}/packages/#{name}/releases/#{version}",
      headers: [{"user-agent", "toolbox"}],
      params: [
        downloads_after: Date.to_iso8601(after_date),
        downloads_before: Date.to_iso8601(before_date)
      ]
    )
  end

  # Without this, a transient error (e.g. a 429) gets cached for the full TTL
  def cacheable_response?({:ok, %Req.Response{status: status}})
      when status in [200, 400, 404],
      do: true

  def cacheable_response?(_other), do: false

  # hexpm hoists prereleases above stable releases
  def stable_versions_desc(releases) do
    releases
    |> Enum.flat_map(fn release ->
      case Version.parse(release["version"]) do
        {:ok, %Version{pre: []} = parsed} -> [{release["version"], parsed}]
        _ -> []
      end
    end)
    |> Enum.sort_by(fn {_version, parsed} -> parsed end, {:desc, Version})
    |> Enum.map(fn {version, _parsed} -> version end)
  end

  if Mix.env() == :test do
    defp base_url, do: ProcessTree.get({__MODULE__, :base_url})
  else
    defp base_url, do: "https://hex.pm/api"
  end
end
