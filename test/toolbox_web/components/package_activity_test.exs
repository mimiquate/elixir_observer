defmodule ToolboxWeb.Components.PackageActivityTest do
  use ToolboxWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ToolboxWeb.Components.PackageActivity

  alias Toolbox.GithubSnapshot.Activity
  alias Toolbox.GithubSnapshot.PullRequest

  describe "package_activity/1" do
    test "renders activity section with GitHub activity data" do
      activity = %Activity{
        open_issue_count: 5,
        closed_issue_count: 23,
        open_pr_count: 2,
        merged_pr_count: 15,
        pull_requests: [
          %PullRequest{
            title: "Fix bug in authentication",
            permalink: "https://github.com/owner/repo/pull/123",
            merged_by_login: "developer1",
            merged_by_avatar_url: "https://avatars.githubusercontent.com/u/123?v=4",
            merged_at: ~U[2024-01-15 10:30:00Z]
          },
          %PullRequest{
            title: "Add new feature for user management",
            permalink: "https://github.com/owner/repo/pull/124",
            merged_by_login: "developer2",
            merged_by_avatar_url: "https://avatars.githubusercontent.com/u/456?v=4",
            merged_at: ~U[2024-01-10 14:20:00Z]
          }
        ]
      }

      html =
        render_component(&package_activity/1,
          activity: activity,
          github_fullname: "owner/repo"
        )

      doc = LazyHTML.from_document(html)

      # Check main activity section exists
      activity_section = LazyHTML.query(doc, "[data-test-activity-section]")
      assert node_count(activity_section) == 1

      # Check activity title
      activity_title = LazyHTML.query(doc, "[data-test-activity-title]")
      assert node_count(activity_title) == 1
      assert LazyHTML.text(activity_title) =~ "Activity"

      # Check "last year" badge is present
      last_year_badge = LazyHTML.query(doc, "[data-test-last-year-badge]")
      assert node_count(last_year_badge) == 1

      # Check pull requests section
      pr_section = LazyHTML.query(doc, "[data-test-pull-requests-section]")
      assert node_count(pr_section) == 1

      pr_title = LazyHTML.query(doc, "[data-test-pull-requests-title]")
      assert node_count(pr_title) == 1
      assert LazyHTML.text(pr_title) =~ "Pull Requests"

      # Check PR counts
      open_pr_count = LazyHTML.query(doc, "[data-test-open-pr-count]")
      assert node_count(open_pr_count) == 1
      assert LazyHTML.text(open_pr_count) =~ "2"

      merged_pr_count = LazyHTML.query(doc, "[data-test-merged-pr-count]")
      assert node_count(merged_pr_count) == 1
      assert LazyHTML.text(merged_pr_count) =~ "15"

      # Check issues section
      issues_section = LazyHTML.query(doc, "[data-test-issues-section]")
      assert node_count(issues_section) == 1

      issues_title = LazyHTML.query(doc, "[data-test-issues-title]")
      assert node_count(issues_title) == 1
      assert LazyHTML.text(issues_title) =~ "Issues"

      # Check issue counts
      open_issue_count = LazyHTML.query(doc, "[data-test-open-issue-count]")
      assert node_count(open_issue_count) == 1
      assert LazyHTML.text(open_issue_count) =~ "5"

      closed_issue_count = LazyHTML.query(doc, "[data-test-closed-issue-count]")
      assert node_count(closed_issue_count) == 1
      assert LazyHTML.text(closed_issue_count) =~ "23"

      # Check latest PRs section
      latest_prs_section = LazyHTML.query(doc, "[data-test-latest-prs-section]")
      assert node_count(latest_prs_section) == 1

      latest_prs_title = LazyHTML.query(doc, "[data-test-latest-prs-title]")
      assert node_count(latest_prs_title) == 1
      assert LazyHTML.text(latest_prs_title) =~ "Latest Merged Pull Requests"

      # Check PR list and individual PRs
      pr_list = LazyHTML.query(doc, "[data-test-pr-list]")
      assert node_count(pr_list) == 1

      pr_items = LazyHTML.query(doc, "[data-test-pr-item]")
      assert node_count(pr_items) == 2

      pr_links = LazyHTML.query(doc, "[data-test-pr-link]")
      assert node_count(pr_links) == 2

      pr_titles = LazyHTML.query(doc, "[data-test-pr-title]")
      assert node_count(pr_titles) == 2

      pr_title_texts =
        Enum.map(pr_titles, fn title ->
          title |> LazyHTML.text() |> String.trim()
        end)

      assert "Fix bug in authentication" in pr_title_texts
      assert "Add new feature for user management" in pr_title_texts

      # Check PR authors
      pr_authors = LazyHTML.query(doc, "[data-test-pr-author]")
      assert node_count(pr_authors) == 2

      pr_author_texts =
        Enum.map(pr_authors, fn author ->
          author |> LazyHTML.text() |> String.trim()
        end)

      assert "developer1" in pr_author_texts
      assert "developer2" in pr_author_texts

      # Check PR avatars
      pr_avatars = LazyHTML.query(doc, "[data-test-pr-avatar]")
      assert node_count(pr_avatars) == 2

      # Check "See all" link
      see_all_link = LazyHTML.query(doc, "[data-test-see-all-link]")
      assert node_count(see_all_link) == 1
      assert LazyHTML.text(see_all_link) =~ "See all"

      # Check "See all" link href
      one_year_ago = Date.add(Date.utc_today(), -365) |> Date.to_iso8601()

      expected_href =
        "https://github.com/owner/repo/pulls?q=is%3Apr+is%3Amerged+created%3A%3E#{one_year_ago}"

      assert LazyHTML.attribute(see_all_link, "href") == [expected_href]

      # Check dividers
      pr_dividers = LazyHTML.query(doc, "[data-test-pr-divider]")
      assert node_count(pr_dividers) >= 1
    end

    test "renders activity section with no pull requests" do
      activity = %Activity{
        open_issue_count: 0,
        closed_issue_count: 5,
        open_pr_count: 0,
        merged_pr_count: 3,
        pull_requests: []
      }

      html =
        render_component(&package_activity/1,
          activity: activity,
          github_fullname: "owner/repo"
        )

      doc = LazyHTML.from_document(html)

      # Check main activity section exists
      activity_section = LazyHTML.query(doc, "[data-test-activity-section]")
      assert node_count(activity_section) == 1

      # Check activity title
      activity_title = LazyHTML.query(doc, "[data-test-activity-title]")
      assert node_count(activity_title) == 1
      assert LazyHTML.text(activity_title) =~ "Activity"

      # Check "No Github activity" message
      no_activity_message = LazyHTML.query(doc, "[data-test-no-activity-message]")
      assert node_count(no_activity_message) == 1
      assert LazyHTML.text(no_activity_message) =~ "No Github activity"

      # Check counts are displayed correctly
      open_pr_count = LazyHTML.query(doc, "[data-test-open-pr-count]")
      assert node_count(open_pr_count) == 1
      assert LazyHTML.text(open_pr_count) =~ "0"

      merged_pr_count = LazyHTML.query(doc, "[data-test-merged-pr-count]")
      assert node_count(merged_pr_count) == 1
      assert LazyHTML.text(merged_pr_count) =~ "3"

      closed_issue_count = LazyHTML.query(doc, "[data-test-closed-issue-count]")
      assert node_count(closed_issue_count) == 1
      assert LazyHTML.text(closed_issue_count) =~ "5"
    end

    test "renders empty state message when there is no Activity" do
      html =
        render_component(&package_activity/1,
          activity: nil,
          github_fullname: "owner/repo"
        )

      doc = LazyHTML.from_document(html)

      # Check main activity section exists
      activity_section = LazyHTML.query(doc, "[data-test-activity-section]")
      assert node_count(activity_section) == 1

      # Check activity title
      activity_title = LazyHTML.query(doc, "[data-test-activity-title]")
      assert node_count(activity_title) == 1
      assert LazyHTML.text(activity_title) =~ "Activity"

      # Check error state elements
      error_state = LazyHTML.query(doc, "[data-test-error-state]")
      assert node_count(error_state) == 1

      error_image = LazyHTML.query(doc, "[data-test-error-image]")
      assert node_count(error_image) == 1

      error_title = LazyHTML.query(doc, "[data-test-error-title]")
      assert node_count(error_title) == 1
      assert LazyHTML.text(error_title) =~ "No Github Activity"

      # Should not show the "last year" badge
      last_year_badge = LazyHTML.query(doc, "[data-test-last-year-badge]")
      assert node_count(last_year_badge) == 0
    end

    test "handles pull requests with dividers correctly" do
      activity = %Activity{
        open_issue_count: 1,
        closed_issue_count: 2,
        open_pr_count: 3,
        merged_pr_count: 4,
        pull_requests: [
          %PullRequest{
            title: "PR 1",
            permalink: "https://github.com/owner/repo/pull/1",
            merged_by_login: "dev1",
            merged_by_avatar_url: "https://avatars.githubusercontent.com/u/1?v=4",
            merged_at: ~U[2024-01-15 10:30:00Z]
          },
          %PullRequest{
            title: "PR 2",
            permalink: "https://github.com/owner/repo/pull/2",
            merged_by_login: "dev2",
            merged_by_avatar_url: "https://avatars.githubusercontent.com/u/2?v=4",
            merged_at: ~U[2024-01-10 14:20:00Z]
          },
          %PullRequest{
            title: "PR 3",
            permalink: "https://github.com/owner/repo/pull/3",
            merged_by_login: "dev3",
            merged_by_avatar_url: "https://avatars.githubusercontent.com/u/3?v=4",
            merged_at: ~U[2024-01-05 09:15:00Z]
          }
        ]
      }

      html =
        render_component(&package_activity/1,
          activity: activity,
          github_fullname: "owner/repo"
        )

      doc = LazyHTML.from_document(html)

      # Check that all PR items are present
      pr_items = LazyHTML.query(doc, "[data-test-pr-item]")
      assert node_count(pr_items) == 3

      # Check that all PR titles are present
      pr_titles = LazyHTML.query(doc, "[data-test-pr-title]")
      assert node_count(pr_titles) == 3

      pr_title_texts =
        Enum.map(pr_titles, fn title ->
          title |> LazyHTML.text() |> String.trim()
        end)

      assert "PR 1" in pr_title_texts
      assert "PR 2" in pr_title_texts
      assert "PR 3" in pr_title_texts

      # Check that all PR authors are present
      pr_authors = LazyHTML.query(doc, "[data-test-pr-author]")
      assert node_count(pr_authors) == 3

      pr_author_texts =
        Enum.map(pr_authors, fn author ->
          author |> LazyHTML.text() |> String.trim()
        end)

      assert "dev1" in pr_author_texts
      assert "dev2" in pr_author_texts
      assert "dev3" in pr_author_texts

      # Check that dividers are present
      pr_dividers = LazyHTML.query(doc, "[data-test-pr-divider]")
      # Should have dividers between PRs (but not after the last one if i < 4 condition)
      assert node_count(pr_dividers) >= 1
    end
  end

  defp node_count(lazy_html) do
    lazy_html
    |> LazyHTML.to_tree()
    |> length()
  end
end
