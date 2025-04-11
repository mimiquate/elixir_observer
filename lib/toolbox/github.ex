defmodule Toolbox.Github do
  @graphql_api_url ~c"https://api.github.com/graphql"

  def get_repo(owner, repository_name) do
    year_ago =
      DateTime.utc_now(:second)
      |> DateTime.shift(month: -12)

    query(
      # FIXME: GitHub graphql doesn't support pullRequest filterBy
      # https://github.com/orgs/community/discussions/24323
      """
      repository(owner: \"#{owner}\", name: \"#{repository_name}\") {
        collaborators(first: 100) {
          nodes {
            login
          }
        }
        createdAt
        description
        isArchived
        issues(first: 100, filterBy: {since: \"#{DateTime.to_iso8601(year_ago)}\"}) {
          nodes {
            state
          }
        }
        languages(first: 20) {
          nodes {
            name
          }
        }
        licenseInfo {
          key
          name
        }
        nameWithOwner
        pullRequests(first: 100, filterBy: {since: \"#{DateTime.to_iso8601(year_ago)}\"}) {
          nodes {
            state
          }
        }
        pushedAt
        repositoryTopics(first: 100) {
          nodes {
            topic {
              name
            }
          }
        }
        stargazerCount
        updatedAt
        watchers {
          totalCount
        }
      }
      """
      |> IO.inspect()
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
