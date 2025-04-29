defmodule Toolbox.Github do
  @graphql_api_url ~c"https://api.github.com/graphql"

  def get_repo(owner, repository_name) do
    year_ago =
      DateTime.utc_now(:second)
      |> DateTime.shift(month: -12)

    query(
      """
      openIssueCount: search(type: ISSUE, query: "type:issue repo:#{owner}/#{repository_name} is:open created:>=#{Calendar.strftime(year_ago, "%x")}") {
        issueCount
      }
      closedIssueCount: search(type: ISSUE, query: "type:issue repo:#{owner}/#{repository_name} is:closed created:>=#{Calendar.strftime(year_ago, "%x")}") {
        issueCount
      }
      openPRCount: search(type: ISSUE, query: "type:pr repo:#{owner}/#{repository_name} is:open created:>=#{Calendar.strftime(year_ago, "%x")}") {
        issueCount
      }
      mergedPRCount: search(type: ISSUE, query: "type:pr repo:#{owner}/#{repository_name} is:merged created:>=#{Calendar.strftime(year_ago, "%x")}") {
        issueCount
      }
      repository(owner: \"#{owner}\", name: \"#{repository_name}\") {
        createdAt
        description
        isArchived
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
        pullRequests(last: 5, states: [MERGED]) {
          nodes {
            createdAt
            mergedAt
            mergedBy {
              login
              avatarUrl(size: 24)
            }
            title
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
