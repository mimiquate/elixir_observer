defmodule Toolbox.Github do
  @base_url "https://api.github.com"
  @graphql_api_url ~c"https://api.github.com/graphql"

  defmodule GithubActivity do
    defstruct [
      :open_issue_count,
      :closed_issue_count,
      :open_pr_count,
      :merged_pr_count,
      :pull_requests
    ]
  end

  def get_repo(owner, repository_name) do
    get("repos/#{owner}/#{repository_name}")
  end

  def get_activity(owner, repository_name) do
    year_ago =
      DateTime.utc_now(:second)
      |> DateTime.shift(month: -12)
      |> Calendar.strftime("%x")

    query = """
      openIssueCount: search(type: ISSUE, query: "type:issue repo:#{owner}/#{repository_name} is:open created:>=#{year_ago}") {
        issueCount
      }
      closedIssueCount: search(type: ISSUE, query: "type:issue repo:#{owner}/#{repository_name} is:closed created:>=#{year_ago}") {
        issueCount
      }
      openPRCount: search(type: ISSUE, query: "type:pr repo:#{owner}/#{repository_name} is:open created:>=#{year_ago}") {
        issueCount
      }
      mergedPRCount: search(type: ISSUE, query: "type:pr repo:#{owner}/#{repository_name} is:merged created:>=#{year_ago}") {
        issueCount
      }
      repository(owner: \"#{owner}\", name: \"#{repository_name}\") {
        pullRequests(last: 5, states: [MERGED]) {
          nodes {
            createdAt
            mergedAt
            permalink
            mergedBy {
              login
              avatarUrl(size: 24)
            }
            title
          }
        }
      }
    """

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

  defp authorization_token do
    Application.fetch_env!(:toolbox, :github_authorization_token)
  end
end
