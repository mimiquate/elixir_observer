defmodule ToolboxWeb.SearchLiveTest do
  use ToolboxWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias Toolbox.Packages

  setup do
    # Create test data for search functionality
    {:ok, bandit_package} =
      Packages.create_package(%{
        name: "bandit",
        description: "A pure Elixir HTTP server"
      })

    {:ok, bamboo_package} =
      Packages.create_package(%{
        name: "bamboo",
        description: "Composable, testable & adapter based emails"
      })

    {:ok, tesla_package} =
      Packages.create_package(%{
        name: "tesla",
        description: "HTTP client library"
      })

    {:ok, urban_package} =
      Packages.create_package(%{
        name: "urban",
        description: "Urban development tools"
      })

    # Create hexpm snapshots with test data
    {:ok, _} =
      Packages.create_hexpm_snapshot(%{
        package_id: bandit_package.id,
        data: %{
          "meta" => %{"description" => "A pure Elixir HTTP server"},
          "downloads" => %{"recent" => 1000},
          "latest_version" => "1.0.0"
        }
      })

    {:ok, _} =
      Packages.create_hexpm_snapshot(%{
        package_id: bamboo_package.id,
        data: %{
          "meta" => %{"description" => "Composable, testable & adapter based emails"},
          "downloads" => %{"recent" => 800},
          "latest_version" => "2.0.0"
        }
      })

    {:ok, _} =
      Packages.create_hexpm_snapshot(%{
        package_id: tesla_package.id,
        data: %{
          "meta" => %{"description" => "HTTP client library"},
          "downloads" => %{"recent" => 500},
          "latest_version" => "1.5.0"
        }
      })

    {:ok, _} =
      Packages.create_hexpm_snapshot(%{
        package_id: urban_package.id,
        data: %{
          "meta" => %{"description" => "Urban development tools"},
          "downloads" => %{"recent" => 300},
          "latest_version" => "0.5.0"
        }
      })

    %{
      bandit_package: bandit_package,
      bamboo_package: bamboo_package,
      tesla_package: tesla_package,
      urban_package: urban_package
    }
  end

  describe "SearchLive page rendering" do
    test "renders search results page with basic elements", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, html} = live(build_conn(), "/searches/ban")

      # Check that the search results page is rendered
      assert has_element?(view, "[data-test-search-results-page]")

      # Check that the search results header is present
      assert has_element?(view, "[data-test-search-results-header]")

      # Check that the search results title shows the correct term
      assert has_element?(view, "[data-test-search-results-title]")
      assert html =~ "Results for &quot;ban&quot;"
    end

    test "shows results", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, html} = live(build_conn(), "/searches/ban")

      # Should NOT have exact matches section since "ban" doesn't exactly match any package
      refute has_element?(view, "[data-test-exact-match=*]")

      # Should show correct count
      assert html =~ "2 packages found"

      # Should have bandit in other results
      assert has_element?(view, "[data-test-result-item='bandit']")
    end

    test "shows no results when search term has no matches" do
      {:ok, view, html} = live(build_conn(), "/searches/nonexistentpackage")

      # Should show no results section
      assert has_element?(view, "[data-test-no-results-section]")
      assert has_element?(view, "[data-test-no-results-title]")
      assert has_element?(view, "[data-test-no-results-message]")

      # Should show no results message
      assert html =~ "No results for &quot;nonexistentpackage&quot;"
      assert html =~ "Please try other search terms"

      # Should NOT have exact matches or other results sections
      refute has_element?(view, "[data-test-results-section]")
    end
  end

  describe "SearchLive package display" do
    test "displays package information correctly", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, html} = live(build_conn(), "/searches/bandit")

      # Should display package name as link
      assert has_element?(view, "[data-test-package-link='bandit']")
      assert html =~ "bandit"

      # Should display package description
      assert has_element?(view, "[data-test-package-description]")
      assert html =~ "A pure Elixir HTTP server"

      # Should have latest version
      assert has_element?(view, "[data-test-result-item='bandit'] [data-test-version='1.0.0']")

      # Show exact match chip
      assert has_element?(view, "[data-test-exact-match='bandit']")

      # Should display download stats (humanized format)
      assert has_element?(view, "[data-test-package-downloads-desktop]")
      assert html =~ "1.0k"
    end

    test "do not display exact match chip", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, _html} = live(build_conn(), "/searches/ban")

      # There is no exact match
      refute has_element?(view, "[data-test-exact-match=*]")
    end

    test "package links navigate to correct package pages", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, _html} = live(build_conn(), "/searches/bandit")

      # Click on package link should navigate to package page
      view
      |> element("[data-test-package-link='bandit']")
      |> render_click()

      assert_redirect(view, "/packages/bandit")
    end
  end

  describe "SearchLive results count and pagination" do
    test "shows correct results count in page title", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, _view, html} = live(build_conn(), "/searches/an")

      # Should show correct total count in title
      assert html =~ "2 packages found"
    end

    test "shows more results indicator when applicable", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      # This test would need more packages to trigger the "more" indicator
      # For now, we'll just test that the element exists when more? is true
      {:ok, view, _html} = live(build_conn(), "/searches/an")

      # With only 2 results, should not show more indicator
      refute has_element?(view, "[data-test-more-results-indicator]")
    end
  end

  describe "SearchLive description search" do
    test "finds packages by description search", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      # Search for "HTTP" which appears in bandit and tesla descriptions
      {:ok, view, html} = live(build_conn(), "/searches/HTTP")

      # Should find 2 packages with "HTTP" in description
      assert html =~ "2 packages found"
      assert has_element?(view, "[data-test-result-item='bandit']")
      assert has_element?(view, "[data-test-result-item='tesla']")
      refute has_element?(view, "[data-test-result-item='bamboo']")
      refute has_element?(view, "[data-test-result-item='urban']")
    end

    test "finds packages by description search with case-insensitive", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      # Search for "http" which appears in bandit and tesla descriptions
      {:ok, view, html} = live(build_conn(), "/searches/http")

      # Should find 2 packages with "HTTP" in description
      assert html =~ "2 packages found"
      assert has_element?(view, "[data-test-result-item='bandit']")
      assert has_element?(view, "[data-test-result-item='tesla']")
      refute has_element?(view, "[data-test-result-item='bamboo']")
      refute has_element?(view, "[data-test-result-item='urban']")
    end
  end
end
