defmodule Toolbox.GitLab do
  @base_url "https://gitlab.com/api/graphql"

  def get_repo(owner, repository_name) do
    query("""
    project(fullPath: \"#{owner}/#{repository_name}\") {
      starCount
    }
    """)
  end

  defp query(query) do
    :httpc.request(
      :post,
      {
        ~c"#{@base_url}",
        [
          {~c"user-agent", "elixir client"}
        ],
        ~c"application/json",
        JSON.encode!(%{"query" => "query { #{query} }"})
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
