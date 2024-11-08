Application.ensure_all_started([:inets, :ssl])

defmodule Hexpm do
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
    |> IO.inspect()
  end
end

1..20
|> Enum.each(fn page ->
  {
    :ok,
    {
      {_, 200, _},
      _headers,
      packages_data
    }
  } =
    Hexpm.get_page(page)

  File.write!("packages_data/packages-#{String.pad_leading("#{page}", 3, "0")}.json", packages_data)

  Process.sleep(5_000)
end)
