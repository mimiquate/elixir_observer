defmodule Toolbox.Github do
  def parse_link(link) do
    Regex.named_captures(
      ~r/^https?:\/\/(?:www\.)?github.com\/(?<owner>[^\/]*)\/(?<repo>[^\/\n]*)/,
      link
    )
  end

  def get_repo(owner, repository_name) do
    get("repos/#{owner}/#{repository_name}")
  end

  def get_activity_and_changelog(owner, repository_name) do
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

        latestTag: refs(refPrefix: "refs/tags/", first: 1, orderBy: {field: TAG_COMMIT_DATE, direction: DESC}) {
          nodes {
            name
            compare(headRef: "main") {
              aheadBy
            }
          }
        }

        changelog: object(expression: "HEAD:CHANGELOG.md") {
          oid
        }
      }
    """

    :httpc.request(
      :post,
      {
        ~c"#{base_url()}/graphql",
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
        ~c"#{base_url()}/#{path}",
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

  def base_url() do
    Application.fetch_env!(:toolbox, :github_base_url)
  end
end
