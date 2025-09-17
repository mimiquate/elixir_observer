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
    :httpc.request(
      :get,
      {
        ~c"#{@base_url}/#{path}",
        [{~c"user-agent", "httpc"}]
      },
      [
        ssl: [
          verify: :verify_peer,
          cacerts: :public_key.cacerts_get()
        ]
      ],
      []
    )
  end

  @decorate cacheable(key: {:hexpm_daily, name, version}, opts: [ttl: :timer.hours(24)])
  def get_daily_downloads(name, version) do
    a = Date.utc_today() |> Date.add(-90)
    get("packages/#{name}/releases/#{version}?downloads=day&downloads_after=#{a}")
  end

  @decorate cacheable(key: {:hexpm_version, name, version}, opts: [ttl: :timer.hours(24)])
  def get_package_version(name, version) do
    get("packages/#{name}/releases/#{version}")
  end

  @decorate cacheable(key: {:hexpm_owner, package_name}, opts: [ttl: :timer.hours(24)])
  def get_package_owners(package_name) do
    :httpc.request(
      :get,
      {
        ~c"#{@base_url}/packages/#{package_name}/owners",
        [{~c"user-agent", "httpc"}]
      },
      [
        ssl: [
          verify: :verify_peer,
          cacerts: :public_key.cacerts_get()
        ]
      ],
      []
    )
  end
end
