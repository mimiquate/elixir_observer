defmodule Toolbox.Hexpm do
  @base_url "https://hex.pm/api"

  def get_page(page) do
    get("packages?sort=downloads&page=#{page}")
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
