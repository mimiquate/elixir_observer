defmodule ToolboxWeb.Components.UnreleasedActivityStatsCardTest do
  use ToolboxWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ToolboxWeb.Components.UnreleasedActivityStatsCard

  describe "unreleased_activity_stats_card/1" do
    test "renders with activity when tag matches latest stable version and has commits" do
      package = %{
        activity: %{
          last_tag: "v1.0.0",
          last_tag_behind_by: 3
        },
        latest_stable_version: "1.0.0",
        github_repo_url: "https://github.com/owner/repo"
      }

      html = render_component(&unreleased_activity_stats_card/1, package: package)
      doc = LazyHTML.from_document(html)

      link = LazyHTML.query(doc, data_test_attr(:unreleased_activity_link))

      assert LazyHTML.attribute(link, "href") == [
               "https://github.com/owner/repo/compare/v1.0.0...HEAD"
             ]

      assert LazyHTML.attribute(link, "target") == ["_blank"]

      # Check link content displays "3 commits"
      link_text = LazyHTML.text(link) |> String.trim() |> String.replace(~r/\s+/, " ")
      assert link_text == "3 commits"
    end

    test "renders 'Unknown' when tag does not match latest stable version" do
      package = %{
        activity: %{
          last_tag: "v1.0.0",
          last_tag_behind_by: 5
        },
        latest_stable_version: "1.1.0",
        github_repo_url: "https://github.com/owner/repo"
      }

      html = render_component(&unreleased_activity_stats_card/1, package: package)
      doc = LazyHTML.from_document(html)

      # Check "Unknown" text is displayed
      content = LazyHTML.query(doc, data_test_attr(:unreleased_activity_content))
      assert node_count(content) == 1
      assert LazyHTML.text(content) =~ "Unknown"

      # Should not have a link
      link = LazyHTML.query(doc, data_test_attr(:unreleased_activity_link))
      assert node_count(link) == 0
    end

    test "renders dash when there is no activity" do
      package = %{
        activity: nil,
        latest_stable_version: "1.0.0",
        github_repo_url: "https://github.com/owner/repo"
      }

      html = render_component(&unreleased_activity_stats_card/1, package: package)
      doc = LazyHTML.from_document(html)

      # Check dash is displayed
      content = LazyHTML.query(doc, data_test_attr(:unreleased_activity_content))
      assert node_count(content) == 1
      assert LazyHTML.text(content) |> String.trim() == "-"

      # Should not have a link
      link = LazyHTML.query(doc, data_test_attr(:unreleased_activity_link))
      assert node_count(link) == 0
    end
  end
end
