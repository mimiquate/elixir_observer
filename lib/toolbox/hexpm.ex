defmodule Toolbox.Hexpm do
  @base_url "https://hex.pm/api"

  use Nebulex.Caching, cache: Toolbox.Cache

  def get_page(page) do
    get("packages?sort=downloads&page=#{page}")
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
