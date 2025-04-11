defmodule Toolbox.Github do
  @graphql_api_url ~c"https://api.github.com/graphql"

  def get_repo(owner, repository_name) do
    query(
      """
      repository(owner: \"#{owner}\", name: \"#{repository_name}\") {
        repositoryTopics(first: 20) {
          nodes {
            topic {
              name
            }
          }
        }
        licenseInfo {
          key
          name
        }
        languages(first: 20) {
          nodes {
            name
          }
        }
        stargazerCount
      }
      """
    )
  end

  defp query(query) do
    :httpc.request(
      :post,
      {
        @graphql_api_url,
        [
          {~c"authorization", "bearer #{authorization_token()}"},
          {~c"user-agent", "elixir client"}
        ],
        ~c"application/json",
        JSON.encode!(%{"query" => "query { #{query} }"})
      },
      [
        ssl: [
          verify: :verify_peer,
          cacerts: :public_key.cacerts_get(),
          # Support wildcard certificates
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
        ]
      ],
      []
    )
  end

  defp authorization_token do
    Application.fetch_env!(:toolbox, :github_authorization_token)
  end
end
