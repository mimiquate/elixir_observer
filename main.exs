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

Hexpm.get()
