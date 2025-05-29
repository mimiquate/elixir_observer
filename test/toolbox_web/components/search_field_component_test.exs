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

      assert html =~ "placeholder=\"Find packages\""
      assert html =~ "name=\"term\""
    end

    test "component handles autofocus attribute" do
      html = render_component(SearchFieldComponent, %{id: "test-search", autofocus: true})

      assert html =~ "autofocus"
    end

    test "component handles class attribute" do
      html = render_component(SearchFieldComponent, %{id: "test-search", class: "custom-class"})

      assert html =~ "custom-class"
    end

    test "initially shows no dropdown" do
      html = render_component(SearchFieldComponent, %{id: "test-search"})

      refute html =~ "absolute top-full"
    end
  end

  describe "SearchFieldComponent search functionality" do
    test "shows dropdown with results when typing valid search term", %{packages: _packages} do
      {:ok, view, _html} = live(build_conn(), "/")

      # Type a search term that should match our test data
      view
      |> element("input[name='term']")
      |> render_change(%{"term" => "ban"})

      # Should show dropdown with results
      assert has_element?(view, "div.absolute.top-full")

      # Check if we have any results (the actual search might return different results)
      html = render(view)
      assert html =~ "bandit"
      refute html =~ "bamboo"
    end

    test "shows 'No results' when search term has no matches" do
      {:ok, view, _html} = live(build_conn(), "/")

      # Type a search term that won't match anything
      view
      |> element("input[name='term']")
      |> render_change(%{"term" => "nonexistentpackage"})

      # Should show dropdown with no results message
      assert has_element?(view, "div.absolute.top-full")
      assert render(view) =~ "No results for &quot;nonexistentpackage&quot;"
    end

    test "doesn't show dropdown for search terms shorter than 2 characters" do
      {:ok, view, _html} = live(build_conn(), "/")

      # Type a single character
      view
      |> element("input[name='term']")
      |> render_change(%{"term" => "b"})

      refute has_element?(view, "div.absolute.top-full")
    end

    test "hides dropdown when search term is cleared" do
      {:ok, view, _html} = live(build_conn(), "/")

      # First show dropdown
      view
      |> element("input[name='term']")
      |> render_change(%{"term" => "ban"})

      # Should show dropdown initially
      assert has_element?(view, "div.absolute.top-full")

      # Clear the search term
      view
      |> element("input[name='term']")
      |> render_change(%{"term" => ""})

      refute has_element?(view, "div.absolute.top-full")
    end
  end

  describe "SearchFieldComponent keyboard navigation" do
    test "hides dropdown on escape key", %{packages: _packages} do
      {:ok, view, _html} = live(build_conn(), "/")

      # First show dropdown
      view
      |> element("input[name='term']")
      |> render_change(%{"term" => "ban"})

      assert has_element?(view, "div.absolute.top-full")

      # Press escape
      view
      |> element("input[name='term']")
      |> render_keydown(%{"key" => "Escape"})

      # Should hide dropdown
      refute has_element?(view, "div.absolute.top-full")
    end

    test "navigates dropdown with arrow keys", %{packages: _packages} do
      {:ok, view, _html} = live(build_conn(), "/")

      # Show dropdown with results
      view
      |> element("input[name='term']")
      |> render_change(%{"term" => "ban"})

      assert has_element?(view, "div.absolute.top-full")

      # Press arrow down - should highlight first item
      view
      |> element("input[name='term']")
      |> render_keydown(%{"key" => "ArrowDown"})

      # Should have highlighted item (bg-surface-alt class)
      assert render(view) =~ "bg-surface-alt"

      # Press arrow down again - should move to next item
      view
      |> element("input[name='term']")
      |> render_keydown(%{"key" => "ArrowDown"})

      # Press arrow up - should move back
      view
      |> element("input[name='term']")
      |> render_keydown(%{"key" => "ArrowUp"})

      # Should still have dropdown visible
      assert has_element?(view, "div.absolute.top-full")
    end
  end

  describe "SearchFieldComponent click interactions" do
    test "clicking on dropdown item navigates to package page", %{packages: _packages} do
      {:ok, view, _html} = live(build_conn(), "/")

      # Show dropdown with results
      view
      |> element("input[name='term']")
      |> render_change(%{"term" => "ban"})

      assert has_element?(view, "div.absolute.top-full")

      # Click on the bandit package
      view
      |> element("li", "bandit")
      |> render_click()

      assert_redirect(view, "/packages/bandit")
    end

    test "submitting form navigates to search results page" do
      {:ok, view, _html} = live(build_conn(), "/")

      # Type search term and submit
      view
      |> element("form")
      |> render_submit(%{"term" => "bandit"})

      # Should redirect to search page
      assert_redirect(view, "/searches/bandit")
    end
  end
end
