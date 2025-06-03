defmodule ToolboxWeb.SearchFieldComponentTest do
  use ToolboxWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias ToolboxWeb.SearchFieldComponent
  alias Toolbox.Packages

  # Create a test LiveView to host our component
  defmodule TestLive do
    use Phoenix.LiveView

    def render(assigns) do
      ~H"""
      <div>
        <.live_component module={SearchFieldComponent} id="test-search" class="test-class" />
      </div>
      """
    end

    def mount(_params, _session, socket) do
      {:ok, socket}
    end
  end

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

  describe "SearchFieldComponent rendering" do
    test "renders search field with placeholder" do
      html = render_component(SearchFieldComponent, %{id: "test-search"})
      doc = Floki.parse_document!(html)

      # Check search container exists
      search_container = Floki.find(doc, "[data-test-search-container]")
      assert length(search_container) == 1

      # Check search form exists
      search_form = Floki.find(doc, "[data-test-search-form]")
      assert length(search_form) == 1

      # Check search input with placeholder
      search_input = Floki.find(doc, "[data-test-search-input]")
      assert length(search_input) == 1
      assert Floki.attribute(search_input, "placeholder") == ["Find packages"]
      assert Floki.attribute(search_input, "name") == ["term"]

      # Check search button exists
      search_button = Floki.find(doc, "[data-test-search-button]")
      assert length(search_button) == 1
    end

    test "component handles autofocus attribute" do
      html = render_component(SearchFieldComponent, %{id: "test-search", autofocus: true})
      doc = Floki.parse_document!(html)

      search_input = Floki.find(doc, "[data-test-search-input]")
      assert length(search_input) == 1
      assert Floki.attribute(search_input, "autofocus") == ["autofocus"]
    end

    test "component handles class attribute" do
      html = render_component(SearchFieldComponent, %{id: "test-search", class: "custom-class"})
      doc = Floki.parse_document!(html)

      search_form = Floki.find(doc, "[data-test-search-form]")
      assert length(search_form) == 1

      form_class = Floki.attribute(search_form, "class") |> List.first()
      assert String.contains?(form_class, "custom-class")
    end

    test "initially shows no dropdown" do
      html = render_component(SearchFieldComponent, %{id: "test-search"})
      doc = Floki.parse_document!(html)

      # Should not have dropdown element
      dropdown = Floki.find(doc, "[data-test-search-dropdown]")
      assert length(dropdown) == 0
    end
  end

  describe "SearchFieldComponent search functionality" do
    test "shows dropdown with results when typing valid search term", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, _html} = live(build_conn(), "/")

      # Type a search term that should match our test data
      view
      |> element("[data-test-search-input]")
      |> render_change(%{"term" => "ban"})

      # Get the updated HTML and parse it
      html = render(view)
      doc = Floki.parse_document!(html)

      # Should show dropdown with results
      dropdown = Floki.find(doc, "[data-test-search-dropdown]")
      assert length(dropdown) == 1

      # Should have results list (either exact matches or other results)
      results_lists =
        Floki.find(doc, "[data-test-exact-matches-list], [data-test-other-results-list]")

      assert length(results_lists) > 0

      # Check if we have result items
      result_items = Floki.find(doc, "[data-test-search-result-item]")
      assert length(result_items) > 0

      # Check if bandit package is in results
      bandit_item = Floki.find(doc, "[data-test-search-result-item='bandit']")
      assert length(bandit_item) == 1

      # Check package name is displayed
      package_names = Floki.find(doc, "[data-test-package-name]")

      package_name_texts =
        Enum.map(package_names, fn element ->
          element |> Floki.text() |> String.trim()
        end)

      assert "bandit" in package_name_texts
    end

    test "shows exact match section when search term exactly matches a package", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, _html} = live(build_conn(), "/")

      # Type search term that matches both bandit and bamboo (both contain "ban")
      view
      |> element("[data-test-search-input]")
      |> render_change(%{"term" => "ban"})

      # Get the updated HTML and parse it
      html = render(view)
      doc = Floki.parse_document!(html)

      # Should show dropdown
      dropdown = Floki.find(doc, "[data-test-search-dropdown]")
      assert length(dropdown) == 1

      # Should NOT have exact matches section since "ban" doesn't exactly match any package
      exact_matches_list =
        Floki.find(doc, "[data-test-search-dropdown] [data-test-exact-matches-list]")

      assert length(exact_matches_list) == 0

      # Should have other results section
      other_results_list = Floki.find(doc, "[data-test-other-results-list]")
      assert length(other_results_list) == 1

      # Should show results count header
      results_count_header =
        Floki.find(doc, "div")
        |> Enum.find(fn element ->
          text = Floki.text(element) |> String.trim()
          String.contains?(text, "Results Found:")
        end)

      assert results_count_header != nil
    end

    test "shows exact match section with exact package name", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, _html} = live(build_conn(), "/")

      # Type exact package name
      view
      |> element("[data-test-search-input]")
      |> render_change(%{"term" => "bandit"})

      # Get the updated HTML and parse it
      html = render(view)
      doc = Floki.parse_document!(html)

      # Should show dropdown
      dropdown = Floki.find(doc, "[data-test-search-dropdown]")
      assert length(dropdown) == 1

      # Should have exact matches section
      exact_matches_list = Floki.find(doc, "[data-test-exact-matches-list]")
      assert length(exact_matches_list) == 1

      # Should show "Exact Match:" header
      exact_match_header =
        Floki.find(doc, "div")
        |> Enum.find(fn element ->
          Floki.text(element) |> String.trim() == "Exact Match:"
        end)

      assert exact_match_header != nil

      # Should have bandit in exact matches
      exact_match_items =
        Floki.find(exact_matches_list, "[data-test-search-result-item='bandit']")

      assert length(exact_match_items) == 1

      # Should NOT have other results section since only bandit matches "bandit"
      other_results_list = Floki.find(doc, "[data-test-other-results-list]")
      assert length(other_results_list) == 0
    end

    test "shows only other results section when no exact match exists", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, _html} = live(build_conn(), "/")

      # Type partial match that doesn't exactly match any package
      view
      |> element("[data-test-search-input]")
      |> render_change(%{"term" => "ban"})

      # Get the updated HTML and parse it
      html = render(view)
      doc = Floki.parse_document!(html)

      # Should show dropdown
      dropdown = Floki.find(doc, "[data-test-search-dropdown]")
      assert length(dropdown) == 1

      # Should NOT have exact matches section
      exact_matches_list = Floki.find(doc, "[data-test-exact-matches-list]")
      assert length(exact_matches_list) == 0

      # Should have other results section
      other_results_list = Floki.find(doc, "[data-test-other-results-list]")
      assert length(other_results_list) == 1

      # Should show results count header
      results_count_header =
        Floki.find(doc, "div")
        |> Enum.find(fn element ->
          text = Floki.text(element) |> String.trim()
          String.contains?(text, "Results Found:")
        end)

      assert results_count_header != nil

      # Should NOT show "Exact Match:" header
      exact_match_header =
        Floki.find(doc, "div")
        |> Enum.find(fn element ->
          Floki.text(element) |> String.trim() == "Exact Match:"
        end)

      assert exact_match_header == nil
    end

    test "exact match is case insensitive", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, _html} = live(build_conn(), "/")

      # Type exact package name in different case
      view
      |> element("[data-test-search-input]")
      |> render_change(%{"term" => "BANDIT"})

      # Get the updated HTML and parse it
      html = render(view)
      doc = Floki.parse_document!(html)

      # Should show dropdown
      dropdown = Floki.find(doc, "[data-test-search-dropdown]")
      assert length(dropdown) == 1

      # Should have exact matches section
      exact_matches_list = Floki.find(doc, "[data-test-exact-matches-list]")
      assert length(exact_matches_list) == 1

      # Should have bandit in exact matches
      exact_match_items =
        Floki.find(exact_matches_list, "[data-test-search-result-item='bandit']")

      assert length(exact_match_items) == 1
    end

    test "shows correct results count in other results section", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, _html} = live(build_conn(), "/")

      # Type search term that matches multiple packages ("an" matches bandit and urban)
      view
      |> element("[data-test-search-input]")
      |> render_change(%{"term" => "an"})

      # Get the updated HTML and parse it
      html = render(view)
      doc = Floki.parse_document!(html)

      # Find the results count header
      results_count_header =
        Floki.find(doc, "div")
        |> Enum.find(fn element ->
          text = Floki.text(element) |> String.trim()
          String.contains?(text, "Results Found:")
        end)

      assert results_count_header != nil

      # Should show count of matches (bandit and urban both contain "an")
      header_text = Floki.text(results_count_header) |> String.trim()
      assert String.contains?(header_text, "2 Results Found:")
    end

    test "shows 'No results' when search term has no matches" do
      {:ok, view, _html} = live(build_conn(), "/")

      # Type a search term that won't match anything
      view
      |> element("[data-test-search-input]")
      |> render_change(%{"term" => "nonexistentpackage"})

      # Get the updated HTML and parse it
      html = render(view)
      doc = Floki.parse_document!(html)

      # Should show dropdown
      dropdown = Floki.find(doc, "[data-test-search-dropdown]")
      assert length(dropdown) == 1

      # Should show no results message
      no_results = Floki.find(doc, "[data-test-no-results-message]")
      assert length(no_results) == 1
      assert Floki.text(no_results) =~ "No results for \"nonexistentpackage\""

      # Should NOT have exact matches or other results sections
      exact_matches_list = Floki.find(doc, "[data-test-exact-matches-list]")
      assert length(exact_matches_list) == 0

      other_results_list = Floki.find(doc, "[data-test-other-results-list]")
      assert length(other_results_list) == 0
    end

    test "doesn't show dropdown for search terms shorter than 2 characters" do
      {:ok, view, _html} = live(build_conn(), "/")

      # Type a single character
      view
      |> element("[data-test-search-input]")
      |> render_change(%{"term" => "b"})

      # Get the updated HTML and parse it
      html = render(view)
      doc = Floki.parse_document!(html)

      # Should not show dropdown
      dropdown = Floki.find(doc, "[data-test-search-dropdown]")
      assert length(dropdown) == 0
    end

    test "hides dropdown when search term is cleared" do
      {:ok, view, _html} = live(build_conn(), "/")

      # First show dropdown
      view
      |> element("[data-test-search-input]")
      |> render_change(%{"term" => "ban"})

      # Verify dropdown is shown
      html = render(view)
      doc = Floki.parse_document!(html)
      dropdown = Floki.find(doc, "[data-test-search-dropdown]")
      assert length(dropdown) == 1

      # Clear the search term
      view
      |> element("[data-test-search-input]")
      |> render_change(%{"term" => ""})

      # Verify dropdown is hidden
      html = render(view)
      doc = Floki.parse_document!(html)
      dropdown = Floki.find(doc, "[data-test-search-dropdown]")
      assert length(dropdown) == 0
    end
  end

  describe "SearchFieldComponent keyboard navigation" do
    test "hides dropdown on escape key", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, _html} = live(build_conn(), "/")

      # First show dropdown
      view
      |> element("[data-test-search-input]")
      |> render_change(%{"term" => "ban"})

      # Verify dropdown is shown
      html = render(view)
      doc = Floki.parse_document!(html)
      dropdown = Floki.find(doc, "[data-test-search-dropdown]")
      assert length(dropdown) == 1

      # Press escape
      view
      |> element("[data-test-search-input]")
      |> render_keydown(%{"key" => "Escape"})

      # Verify dropdown is hidden
      html = render(view)
      doc = Floki.parse_document!(html)
      dropdown = Floki.find(doc, "[data-test-search-dropdown]")
      assert length(dropdown) == 0
    end

    test "navigates dropdown with arrow keys in exact match section", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, _html} = live(build_conn(), "/")

      # Show dropdown with search that returns multiple results
      # Use "an" which matches both bandit and urban
      view
      |> element("[data-test-search-input]")
      |> render_change(%{"term" => "an"})

      # Verify dropdown is shown
      html = render(view)
      doc = Floki.parse_document!(html)
      dropdown = Floki.find(doc, "[data-test-search-dropdown]")
      assert length(dropdown) == 1

      # Press arrow down - should highlight first item
      view
      |> element("[data-test-search-input]")
      |> render_keydown(%{"key" => "ArrowDown"})

      # Check that first item is highlighted
      html = render(view)
      doc = Floki.parse_document!(html)

      # Find the item with index 0 (first item)
      first_item = Floki.find(doc, "[data-test-search-result-index='0']")
      assert length(first_item) == 1

      # Check if it has the highlighted class
      first_item_class = Floki.attribute(first_item, "class") |> List.first()
      assert String.contains?(first_item_class, "bg-surface-alt")

      # Press arrow down again - should move to next item
      view
      |> element("[data-test-search-input]")
      |> render_keydown(%{"key" => "ArrowDown"})

      # Check that second item is highlighted
      html = render(view)
      doc = Floki.parse_document!(html)
      second_item = Floki.find(doc, "[data-test-search-result-index='1']")
      assert length(second_item) == 1

      second_item_class = Floki.attribute(second_item, "class") |> List.first()
      assert String.contains?(second_item_class, "bg-surface-alt")

      # Press arrow up - should move back to first item
      view
      |> element("[data-test-search-input]")
      |> render_keydown(%{"key" => "ArrowUp"})

      # Should still have dropdown visible
      html = render(view)
      doc = Floki.parse_document!(html)
      dropdown = Floki.find(doc, "[data-test-search-dropdown]")
      assert length(dropdown) == 1
    end

    test "navigates dropdown with arrow keys in other results only", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, _html} = live(build_conn(), "/")

      # Show dropdown with partial match (no exact match)
      view
      |> element("[data-test-search-input]")
      |> render_change(%{"term" => "ban"})

      # Verify dropdown is shown
      html = render(view)
      doc = Floki.parse_document!(html)
      dropdown = Floki.find(doc, "[data-test-search-dropdown]")
      assert length(dropdown) == 1

      # Should NOT have exact matches section
      exact_matches_list = Floki.find(doc, "[data-test-exact-matches-list]")
      assert length(exact_matches_list) == 0

      # Press arrow down - should highlight first item in other results
      view
      |> element("[data-test-search-input]")
      |> render_keydown(%{"key" => "ArrowDown"})

      # Check that first item is highlighted
      html = render(view)
      doc = Floki.parse_document!(html)

      # Find the item with index 0 (first item in other results)
      first_item = Floki.find(doc, "[data-test-search-result-index='0']")
      assert length(first_item) == 1

      # Check if it has the highlighted class
      first_item_class = Floki.attribute(first_item, "class") |> List.first()
      assert String.contains?(first_item_class, "bg-surface-alt")
    end

    # test "enter key selects highlighted item from exact match section", %{
    #   bandit_package: _bandit_package,
    #   bamboo_package: _bamboo_package,
    #   tesla_package: _tesla_package,
    #   urban_package: _urban_package
    # } do
    #   {:ok, view, _html} = live(build_conn(), "/")

    #   # Show dropdown with exact match
    #   view
    #   |> element("[data-test-search-input]")
    #   |> render_change(%{"term" => "bandit"})

    #   # Press arrow down to select first item (exact match)
    #   view
    #   |> element("[data-test-search-input]")
    #   |> render_keydown(%{"key" => "ArrowDown"})

    #   # Press enter to select
    #   view
    #   |> element("[data-test-search-input]")
    #   |> render_keydown(%{"key" => "Enter"})

    #   # Should redirect to bandit package page
    #   assert_redirect(view, "/packages/bandit")
    # end

    # test "enter key selects highlighted item from other results section", %{
    #   bandit_package: _bandit_package,
    #   bamboo_package: _bamboo_package,
    #   tesla_package: _tesla_package,
    #   urban_package: _urban_package
    # } do
    #   {:ok, view, _html} = live(build_conn(), "/")

    #   # Show dropdown with multiple matches
    #   view
    #   |> element("[data-test-search-input]")
    #   |> render_change(%{"term" => "an"})

    #   # Press arrow down to get to first item
    #   view
    #   |> element("[data-test-search-input]")
    #   |> render_keydown(%{"key" => "ArrowDown"})

    #   # Press enter to select
    #   view
    #   |> element("[data-test-search-input]")
    #   |> render_keydown(%{"key" => "Enter"})

    #   # Should redirect to the first package page (bandit has higher downloads)
    #   assert_redirect(view, "/packages/bandit")
    # end
  end

  describe "SearchFieldComponent click interactions" do
    test "clicking on dropdown item navigates to package page", %{
      bandit_package: _bandit_package,
      bamboo_package: _bamboo_package,
      tesla_package: _tesla_package,
      urban_package: _urban_package
    } do
      {:ok, view, _html} = live(build_conn(), "/")

      # Show dropdown with results
      view
      |> element("[data-test-search-input]")
      |> render_change(%{"term" => "ban"})

      # Verify dropdown is shown
      html = render(view)
      doc = Floki.parse_document!(html)
      dropdown = Floki.find(doc, "[data-test-search-dropdown]")
      assert length(dropdown) == 1

      # Click on the bandit package
      view
      |> element("[data-test-search-result-item='bandit']")
      |> render_click()

      assert_redirect(view, "/packages/bandit")
    end

    test "submitting form navigates to search results page" do
      {:ok, view, _html} = live(build_conn(), "/")

      # Type search term and submit
      view
      |> element("[data-test-search-form]")
      |> render_submit(%{"term" => "bandit"})

      # Should redirect to search page
      assert_redirect(view, "/searches/bandit")
    end
  end
end
