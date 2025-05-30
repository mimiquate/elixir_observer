defmodule ToolboxWeb.Components.PackageActivityTest do
  use ToolboxWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ToolboxWeb.Components.PackageActivity

  alias Toolbox.Packages.GitHubActivity

  describe "package_activity/1" do
    test "renders activity section with GitHub activity data" do
      activity = %GitHubActivity{
        open_issue_count: 5,
        closed_issue_count: 23,
        open_pr_count: 2,
        merged_pr_count: 15,
        pull_requests: [
          %{
            "title" => "Fix bug in authentication",
            "permalink" => "https://github.com/owner/repo/pull/123",
            "mergedBy" => %{
              "login" => "developer1",
              "avatarUrl" => "https://avatars.githubusercontent.com/u/123?v=4"
            },
            "mergedAt" => "2024-01-15T10:30:00Z"
          },
          %{
            "title" => "Add new feature for user management",
            "permalink" => "https://github.com/owner/repo/pull/124",
            "mergedBy" => %{
              "login" => "developer2",
              "avatarUrl" => "https://avatars.githubusercontent.com/u/456?v=4"
            },
            "mergedAt" => "2024-01-10T14:20:00Z"
          }
        ]
      }

      html =
        render_component(&package_activity/1,
          activity: activity,
          github_fullname: "owner/repo"
        )

      # Check main structure
      assert html =~ "Activity"
      assert html =~ "last year"

      # Check pull requests section
      assert html =~ "Pull Requests"
      assert html =~ "Open"
      assert html =~ "2"
      assert html =~ "Merged"
      assert html =~ "15"

      # Check issues section
      assert html =~ "Issues"
      assert html =~ "5"
      assert html =~ "23"

      # Check latest merged pull requests
      assert html =~ "Latest Merged Pull Requests"
      assert html =~ "Fix bug in authentication"
      assert html =~ "Add new feature for user management"
      assert html =~ "developer1"
      assert html =~ "developer2"
      assert html =~ "https://github.com/owner/repo/pull/123"
      assert html =~ "https://github.com/owner/repo/pull/124"

      # Check "See all" link
      assert html =~ "See all"
      assert html =~ "https://github.com/owner/repo/pulls"
    end

    test "renders activity section with no pull requests" do
      activity = %GitHubActivity{
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

      assert html =~ "Activity"
      assert html =~ "No Github activity"
      assert html =~ "0"
      assert html =~ "3"
      assert html =~ "5"
    end

    test "renders activity section without github_fullname" do
      activity = %GitHubActivity{
        open_issue_count: 1,
        closed_issue_count: 2,
        open_pr_count: 3,
        merged_pr_count: 4,
        pull_requests: []
      }

      html =
        render_component(&package_activity/1,
          activity: activity,
          github_fullname: nil
        )

      assert html =~ "Activity"
      assert html =~ "1"
      assert html =~ "2"
      assert html =~ "3"
      assert html =~ "4"
      # Should not render "See all" link when no github_fullname
      refute html =~ "See all"
    end

    test "renders error state when activity is not GitHubActivity struct" do
      html =
        render_component(&package_activity/1,
          activity: %{error: "Failed to load"},
          github_fullname: "owner/repo"
        )

      assert html =~ "Activity"
      assert html =~ "Failed to load repo activity"
      assert html =~ "Please refresh in a bit"
      assert html =~ "/images/error-illustration.png"
      # Should not show the "last year" badge
      refute html =~ "last year"
    end

    test "renders with custom CSS class" do
      activity = %GitHubActivity{
        open_issue_count: 1,
        closed_issue_count: 2,
        open_pr_count: 3,
        merged_pr_count: 4,
        pull_requests: []
      }

      html =
        render_component(&package_activity/1,
          activity: activity,
          github_fullname: "owner/repo",
          class: "custom-class"
        )

      assert html =~ "custom-class"
    end

    test "handles pull requests with dividers correctly" do
      activity = %GitHubActivity{
        open_issue_count: 1,
        closed_issue_count: 2,
        open_pr_count: 3,
        merged_pr_count: 4,
        pull_requests: [
          %{
            "title" => "PR 1",
            "permalink" => "https://github.com/owner/repo/pull/1",
            "mergedBy" => %{
              "login" => "dev1",
              "avatarUrl" => "https://avatars.githubusercontent.com/u/1?v=4"
            },
            "mergedAt" => "2024-01-15T10:30:00Z"
          },
          %{
            "title" => "PR 2",
            "permalink" => "https://github.com/owner/repo/pull/2",
            "mergedBy" => %{
              "login" => "dev2",
              "avatarUrl" => "https://avatars.githubusercontent.com/u/2?v=4"
            },
            "mergedAt" => "2024-01-10T14:20:00Z"
          },
          %{
            "title" => "PR 3",
            "permalink" => "https://github.com/owner/repo/pull/3",
            "mergedBy" => %{
              "login" => "dev3",
              "avatarUrl" => "https://avatars.githubusercontent.com/u/3?v=4"
            },
            "mergedAt" => "2024-01-05T09:15:00Z"
          }
        ]
      }

      html =
        render_component(&package_activity/1,
          activity: activity,
          github_fullname: "owner/repo"
        )

      assert html =~ "PR 1"
      assert html =~ "PR 2"
      assert html =~ "PR 3"
      # Check that dividers are present (border-divider class)
      assert html =~ "border-divider"
    end

    test "renders activity section with nil activity" do
      html =
        render_component(&package_activity/1,
          activity: nil,
          github_fullname: "owner/repo"
        )

      assert html =~ "Activity"
      assert html =~ "Failed to load repo activity"
      assert html =~ "Please refresh in a bit"
    end
  end
end
