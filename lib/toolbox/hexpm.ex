defmodule Toolbox.Hexpm do
  @base_url "https://hex.pm/api"

  def get_page(page) do
    :httpc.request(
      :get,
      {
        ~c"#{@base_url}/packages?sort=downloads&page=#{page}",
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

  def get_package_release(package_name, version) do
    :httpc.request(
      :get,
      {
        ~c"#{@base_url}/packages/#{package_name}/releases/#{version}",
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
