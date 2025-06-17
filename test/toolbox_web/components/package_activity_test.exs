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

      doc = Floki.parse_document!(html)

      # Check main activity section exists
      activity_section = Floki.find(doc, "[data-test-activity-section]")
      assert length(activity_section) == 1

      # Check activity title
      activity_title = Floki.find(doc, "[data-test-activity-title]")
      assert length(activity_title) == 1
      assert Floki.text(activity_title) =~ "Activity"

      # Check "last year" badge is present
      last_year_badge = Floki.find(doc, "[data-test-last-year-badge]")
      assert length(last_year_badge) == 1

      # Check pull requests section
      pr_section = Floki.find(doc, "[data-test-pull-requests-section]")
      assert length(pr_section) == 1

      pr_title = Floki.find(doc, "[data-test-pull-requests-title]")
      assert length(pr_title) == 1
      assert Floki.text(pr_title) =~ "Pull Requests"

      # Check PR counts
      open_pr_count = Floki.find(doc, "[data-test-open-pr-count]")
      assert length(open_pr_count) == 1
      assert Floki.text(open_pr_count) =~ "2"

      merged_pr_count = Floki.find(doc, "[data-test-merged-pr-count]")
      assert length(merged_pr_count) == 1
      assert Floki.text(merged_pr_count) =~ "15"

      # Check issues section
      issues_section = Floki.find(doc, "[data-test-issues-section]")
      assert length(issues_section) == 1

      issues_title = Floki.find(doc, "[data-test-issues-title]")
      assert length(issues_title) == 1
      assert Floki.text(issues_title) =~ "Issues"

      # Check issue counts
      open_issue_count = Floki.find(doc, "[data-test-open-issue-count]")
      assert length(open_issue_count) == 1
      assert Floki.text(open_issue_count) =~ "5"

      closed_issue_count = Floki.find(doc, "[data-test-closed-issue-count]")
      assert length(closed_issue_count) == 1
      assert Floki.text(closed_issue_count) =~ "23"

      # Check latest PRs section
      latest_prs_section = Floki.find(doc, "[data-test-latest-prs-section]")
      assert length(latest_prs_section) == 1

      latest_prs_title = Floki.find(doc, "[data-test-latest-prs-title]")
      assert length(latest_prs_title) == 1
      assert Floki.text(latest_prs_title) =~ "Latest Merged Pull Requests"

      # Check PR list and individual PRs
      pr_list = Floki.find(doc, "[data-test-pr-list]")
      assert length(pr_list) == 1

      pr_items = Floki.find(doc, "[data-test-pr-item]")
      assert length(pr_items) == 2

      pr_links = Floki.find(doc, "[data-test-pr-link]")
      assert length(pr_links) == 2

      pr_titles = Floki.find(doc, "[data-test-pr-title]")
      assert length(pr_titles) == 2

      pr_title_texts =
        Enum.map(pr_titles, fn title ->
          title |> Floki.text() |> String.trim()
        end)

      assert "Fix bug in authentication" in pr_title_texts
      assert "Add new feature for user management" in pr_title_texts

      # Check PR authors
      pr_authors = Floki.find(doc, "[data-test-pr-author]")
      assert length(pr_authors) == 2

      pr_author_texts =
        Enum.map(pr_authors, fn author ->
          author |> Floki.text() |> String.trim()
        end)

      assert "developer1" in pr_author_texts
      assert "developer2" in pr_author_texts

      # Check PR avatars
      pr_avatars = Floki.find(doc, "[data-test-pr-avatar]")
      assert length(pr_avatars) == 2

      # Check "See all" link
      see_all_link = Floki.find(doc, "[data-test-see-all-link]")
      assert length(see_all_link) == 1
      assert Floki.text(see_all_link) =~ "See all"

      # Check dividers
      pr_dividers = Floki.find(doc, "[data-test-pr-divider]")
      assert length(pr_dividers) >= 1
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

      doc = Floki.parse_document!(html)

      # Check main activity section exists
      activity_section = Floki.find(doc, "[data-test-activity-section]")
      assert length(activity_section) == 1

      # Check activity title
      activity_title = Floki.find(doc, "[data-test-activity-title]")
      assert length(activity_title) == 1
      assert Floki.text(activity_title) =~ "Activity"

      # Check "No Github activity" message
      no_activity_message = Floki.find(doc, "[data-test-no-activity-message]")
      assert length(no_activity_message) == 1
      assert Floki.text(no_activity_message) =~ "No Github activity"

      # Check counts are displayed correctly
      open_pr_count = Floki.find(doc, "[data-test-open-pr-count]")
      assert length(open_pr_count) == 1
      assert Floki.text(open_pr_count) =~ "0"

      merged_pr_count = Floki.find(doc, "[data-test-merged-pr-count]")
      assert length(merged_pr_count) == 1
      assert Floki.text(merged_pr_count) =~ "3"

      closed_issue_count = Floki.find(doc, "[data-test-closed-issue-count]")
      assert length(closed_issue_count) == 1
      assert Floki.text(closed_issue_count) =~ "5"
    end

    test "renders empty state message when there is no Activity" do
      html =
        render_component(&package_activity/1,
          activity: nil,
          github_fullname: "owner/repo"
        )

      doc = Floki.parse_document!(html)

      # Check main activity section exists
      activity_section = Floki.find(doc, "[data-test-activity-section]")
      assert length(activity_section) == 1

      # Check activity title
      activity_title = Floki.find(doc, "[data-test-activity-title]")
      assert length(activity_title) == 1
      assert Floki.text(activity_title) =~ "Activity"

      # Check error state elements
      error_state = Floki.find(doc, "[data-test-error-state]")
      assert length(error_state) == 1

      error_image = Floki.find(doc, "[data-test-error-image]")
      assert length(error_image) == 1

      error_title = Floki.find(doc, "[data-test-error-title]")
      assert length(error_title) == 1
      assert Floki.text(error_title) =~ "No Github Activity"

      # Should not show the "last year" badge
      last_year_badge = Floki.find(doc, "[data-test-last-year-badge]")
      assert length(last_year_badge) == 0
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

      doc = Floki.parse_document!(html)

      # Check that all PR items are present
      pr_items = Floki.find(doc, "[data-test-pr-item]")
      assert length(pr_items) == 3

      # Check that all PR titles are present
      pr_titles = Floki.find(doc, "[data-test-pr-title]")
      assert length(pr_titles) == 3

      pr_title_texts =
        Enum.map(pr_titles, fn title ->
          title |> Floki.text() |> String.trim()
        end)

      assert "PR 1" in pr_title_texts
      assert "PR 2" in pr_title_texts
      assert "PR 3" in pr_title_texts

      # Check that all PR authors are present
      pr_authors = Floki.find(doc, "[data-test-pr-author]")
      assert length(pr_authors) == 3

      pr_author_texts =
        Enum.map(pr_authors, fn author ->
          author |> Floki.text() |> String.trim()
        end)

      assert "dev1" in pr_author_texts
      assert "dev2" in pr_author_texts
      assert "dev3" in pr_author_texts

      # Check that dividers are present
      pr_dividers = Floki.find(doc, "[data-test-pr-divider]")
      # Should have dividers between PRs (but not after the last one if i < 4 condition)
      assert length(pr_dividers) >= 1
    end
  end
end
