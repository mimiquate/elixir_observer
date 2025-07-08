defmodule Toolbox.GithubSnapshot.Activity do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :open_issue_count, :integer
    field :closed_issue_count, :integer
    field :open_pr_count, :integer
    field :merged_pr_count, :integer
    field :last_tag, :string
    field :last_tag_behind_by, :integer
    embeds_many :pull_requests, Toolbox.GithubSnapshot.PullRequest
  end

  def changeset(activity, attrs) do
    fields = [
      :open_issue_count,
      :closed_issue_count,
      :open_pr_count,
      :merged_pr_count,
      :last_tag,
      :last_tag_behind_by
    ]

    activity
    |> cast(attrs, fields)
    |> cast_embed(:pull_requests)
    |> validate_required(fields)
  end

  def build_from_api_response(response) do
    year_ago = DateTime.utc_now() |> DateTime.shift(year: -1)

    pull_requests =
      get_in(response, ["data", "repository", "pullRequests", "nodes"])
      # Filtering in memory because the api does not provide a way for doing it
      |> Enum.filter(fn p ->
        {:ok, p_created_at, _} = DateTime.from_iso8601(p["createdAt"])

        DateTime.diff(p_created_at, year_ago) > 0
      end)
      |> Enum.reverse()
      |> Enum.map(fn p ->
        %{
          permalink: p["permalink"],
          created_at: p["createdAt"],
          title: p["title"],
          merged_at: p["mergedAt"],
          merged_by_login: p["mergedBy"]["login"],
          merged_by_avatar_url: p["mergedBy"]["avatarUrl"]
        }
      end)

    latest_tag = get_in(response, ["data", "repository", "latestTag", "nodes"]) |> List.first()

    %{
      open_issue_count: get_in(response, ["data", "openIssueCount", "issueCount"]),
      closed_issue_count: get_in(response, ["data", "closedIssueCount", "issueCount"]),
      open_pr_count: get_in(response, ["data", "openPRCount", "issueCount"]),
      merged_pr_count: get_in(response, ["data", "mergedPRCount", "issueCount"]),
      last_tag: get_in(latest_tag, ["name"]),
      last_tag_behind_by: get_in(latest_tag, ["compare", "aheadBy"]),
      pull_requests: pull_requests
    }
  end
end
