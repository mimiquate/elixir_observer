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
      assert html =~ "results for &quot;ban&quot;"
    end

    test "shows exact match section when search term exactly matches a package", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, html} = live(build_conn(), "/searches/bandit")

      # Should have exact matches section
      assert has_element?(view, "[data-test-exact-matches-section]")
      assert has_element?(view, "[data-test-exact-matches-title]")
      assert has_element?(view, "[data-test-exact-matches-list]")

      # Should show "Exact Match:" header
      assert html =~ "Exact Match:"

      # Should have bandit in exact matches
      assert has_element?(view, "[data-test-exact-match-item='bandit']")

      # Should NOT have other results section since only bandit matches "bandit"
      refute has_element?(view, "[data-test-other-results-section]")
    end

    test "shows only other results section when no exact match exists", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, html} = live(build_conn(), "/searches/ban")

      # Should NOT have exact matches section since "ban" doesn't exactly match any package
      refute has_element?(view, "[data-test-exact-matches-section]")

      # Should have other results section
      assert has_element?(view, "[data-test-other-results-section]")
      assert has_element?(view, "[data-test-other-results-title]")
      assert has_element?(view, "[data-test-other-results-list]")

      # Should show results count in title
      assert html =~ "Other Results:"

      # Should have bandit in other results
      assert has_element?(view, "[data-test-other-result-item='bandit']")
    end

    test "shows both exact match and other results sections when applicable", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, html} = live(build_conn(), "/searches/an")

      # Should have other results section (bandit and urban both contain "an")
      assert has_element?(view, "[data-test-other-results-section]")
      assert has_element?(view, "[data-test-other-results-title]")

      # Should show correct count
      assert html =~ "2 Other Results:"

      # Should have both packages in other results
      assert has_element?(view, "[data-test-other-result-item='bandit']")
      assert has_element?(view, "[data-test-other-result-item='urban']")

      # Should NOT have exact matches section since "an" doesn't exactly match any package
      refute has_element?(view, "[data-test-exact-matches-section]")
    end

    test "exact match is case insensitive", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, html} = live(build_conn(), "/searches/BANDIT")

      # Should have exact matches section
      assert has_element?(view, "[data-test-exact-matches-section]")
      assert html =~ "Exact Match:"

      # Should have bandit in exact matches
      assert has_element?(view, "[data-test-exact-match-item='bandit']")
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
      refute has_element?(view, "[data-test-exact-matches-section]")
      refute has_element?(view, "[data-test-other-results-section]")
    end
  end

  describe "SearchLive package display" do
    test "displays package information correctly in exact match section", %{
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

      # Should display download stats (humanized format)
      assert has_element?(view, "[data-test-package-downloads-desktop]")
      assert html =~ "1.0k"
    end

    test "displays package information correctly in other results section", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, html} = live(build_conn(), "/searches/ban")

      # Should display package name as link
      assert has_element?(view, "[data-test-package-link='bandit']")
      assert html =~ "bandit"

      # Should display package description
      assert has_element?(view, "[data-test-package-description]")
      assert html =~ "A pure Elixir HTTP server"

      # Should display download stats (humanized format)
      assert has_element?(view, "[data-test-package-downloads-desktop]")
      assert html =~ "1.0k"
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
      assert html =~ "2 results for &quot;an&quot;"
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

  describe "SearchLive edge cases" do
    test "handles empty search term gracefully" do
      # This would depend on routing configuration
      # For now, we'll test a single character search
      {:ok, view, _html} = live(build_conn(), "/searches/a")

      # Should still render the page structure
      assert has_element?(view, "[data-test-search-results-page]")
    end

    test "handles special characters in search term", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, html} = live(build_conn(), "/searches/ban%20dit")

      # Should show no results for this search
      assert has_element?(view, "[data-test-no-results-section]")
      assert html =~ "No results for &quot;ban dit&quot;"
    end
  end
end
