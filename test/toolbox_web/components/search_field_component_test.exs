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
    {:ok, package1} = Packages.create_package(%{name: "bandit"})
    {:ok, package2} = Packages.create_package(%{name: "bamboo"})
    {:ok, package3} = Packages.create_package(%{name: "tesla"})

    # Create hexpm snapshots with test data
    {:ok, _} =
      Packages.create_hexpm_snapshot(%{
        package_id: package1.id,
        data: %{
          "meta" => %{"description" => "A pure Elixir HTTP server"},
          "downloads" => %{"recent" => 1000},
          "latest_version" => "1.0.0"
        }
      })

    {:ok, _} =
      Packages.create_hexpm_snapshot(%{
        package_id: package2.id,
        data: %{
          "meta" => %{"description" => "Composable, testable & adapter based emails"},
          "downloads" => %{"recent" => 800},
          "latest_version" => "2.0.0"
        }
      })

    {:ok, _} =
      Packages.create_hexpm_snapshot(%{
        package_id: package3.id,
        data: %{
          "meta" => %{"description" => "HTTP client library"},
          "downloads" => %{"recent" => 500},
          "latest_version" => "1.5.0"
        }
      })

    %{packages: [package1, package2, package3]}
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
    test "shows dropdown with results when typing valid search term", %{packages: _packages} do
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

      # Should have results list
      results_list = Floki.find(doc, "[data-test-search-results-list]")
      assert length(results_list) == 1

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
    test "hides dropdown on escape key", %{packages: _packages} do
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

    test "navigates dropdown with arrow keys", %{packages: _packages} do
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

      # Press arrow up - should move back
      view
      |> element("[data-test-search-input]")
      |> render_keydown(%{"key" => "ArrowUp"})

      # Should still have dropdown visible
      html = render(view)
      doc = Floki.parse_document!(html)
      dropdown = Floki.find(doc, "[data-test-search-dropdown]")
      assert length(dropdown) == 1
    end
  end

  describe "SearchFieldComponent click interactions" do
    test "clicking on dropdown item navigates to package page", %{packages: _packages} do
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
