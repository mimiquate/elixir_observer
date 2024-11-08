Application.ensure_all_started([:inets, :ssl])

defmodule Hexpm do
  @base_url "https://hex.pm/api"

  def get do
    :httpc.request(
      :get,
      {
        ~c"#{@base_url}/packages",
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
    |> IO.inspect()
  end
end

{
  :ok,
  {
    {_, 200, _},
    _headers,
    packages_data
  }
} =
  Hexpm.get()

File.write!("packages.json", packages_data)
