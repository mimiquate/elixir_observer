defmodule Toolbox.Hexpm do
  @base_url "https://hex.pm/api"

  use Nebulex.Caching, cache: Toolbox.Cache

  def get_page(page) do
    get("packages?sort=inserted_at&page=#{page}")
  end

  def get_package(name) do
    get("packages/#{name}")
  end

  def get(path) do
    Req.get("#{@base_url}/#{path}", headers: [{"user-agent", "toolbox"}])
  end

  @decorate cacheable(key: {:hexpm_version, name, version}, opts: [ttl: :timer.hours(24)])
  def get_package_version(name, version) do
    get("packages/#{name}/releases/#{version}")
  end

  @decorate cacheable(key: {:hexpm_owner, package_name}, opts: [ttl: :timer.hours(24)])
  def get_package_owners(package_name) do
    Req.get("#{@base_url}/packages/#{package_name}/owners", headers: [{"user-agent", "toolbox"}])
  end
end
