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
end
