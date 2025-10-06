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
      query {
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
              compare(headRef: "HEAD") {
                aheadBy
              }
            }
          }

          changelog: object(expression: "HEAD:CHANGELOG.md") {
            oid
          }
        }
      }
    """

    Req.post(
      url: "#{base_url()}/graphql",
      headers: [
        {"authorization", "Bearer #{authorization_token()}"},
        {"user-agent", "toolbox"}
      ],
      json: %{"query" => query}
    )
  end

  defp get(path) do
    Req.get("#{base_url()}/#{path}",
      headers: [
        {"authorization", "Bearer #{authorization_token()}"},
        {"user-agent", "toolbox"}
      ]
    )
  end

  defp authorization_token do
    Application.fetch_env!(:toolbox, :github_authorization_token)
  end

  def base_url() do
    Application.fetch_env!(:toolbox, :github_base_url)
  end
end
