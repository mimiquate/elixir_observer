defmodule Toolbox.Github do
  @base_url "https://api.github.com"

  def get_repo(owner, repository_name) do
    get("repos/#{owner}/#{repository_name}")
  end

  def get_repo2(owner, repository_name) do
    graphql_query(
      # FIXME: newline escaping needed
      """
      repository(owner: \\\"#{owner}\\\", name: \\\"#{repository_name}\\\") {
        issues(last: 20) { edges { node { state } } }
        pullRequests(last: 20) { edges { node { state } } }
        repositoryTopics
        licenseInfo
        languages
        stargazerCount
      }
      """
    )
  end

  defp get(path) do
    :httpc.request(
      :get,
      {
        ~c"#{@base_url}/#{path}",
        [
          {~c"authorization", "Bearer #{authorization_token()}"},
          {~c"user-agent", "elixir client"}
        ]
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

  defp graphql_query(query) do
    post("graphql", "{\"query\": \"query { #{query} }\"}")
  end

  defp post(path, body) do
    :httpc.request(
      :post,
      {
        ~c"#{@base_url}/#{path}",
        [
          {~c"authorization", "bearer #{authorization_token()}"},
          {~c"user-agent", "elixir client"}
        ],
        ~c"application/json",
        body|>IO.inspect()
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
