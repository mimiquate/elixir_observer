defmodule ToolboxWeb.CategoryIndexLiveTest do
  use ToolboxWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Toolbox.{Category, Packages}

  setup do
    Toolbox.Cache.delete_all()

    {:ok, bandit_package} =
      Packages.create_package(%{
        name: "bandit",
        description: "A pure Elixir HTTP server",
        category: Category.find_by_name("HTTP Server")
      })

    {:ok, tesla_package} =
      Packages.create_package(%{
        name: "tesla",
        description: "HTTP client library",
        category: Category.find_by_name("HTTP Client")
      })

    {:ok, bamboo_package} =
      Packages.create_package(%{
        name: "bamboo",
        description: "Composable, testable & adapter based emails",
        category: Category.find_by_name("Email")
      })

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
        package_id: tesla_package.id,
        data: %{
          "meta" => %{"description" => "HTTP client library"},
          "downloads" => %{"recent" => 800},
          "latest_version" => "1.5.0"
        }
      })

    {:ok, _} =
      Packages.create_hexpm_snapshot(%{
        package_id: bamboo_package.id,
        data: %{
          "meta" => %{"description" => "Composable, testable & adapter based emails"},
          "downloads" => %{"recent" => 600},
          "latest_version" => "2.0.0"
        }
      })

    %{
      bandit_package: bandit_package,
      tesla_package: tesla_package,
      bamboo_package: bamboo_package
    }
  end

  describe "CategoryIndexLive page rendering" do
    test "renders categories", %{
      bandit_package: _bandit_package,
      tesla_package: _tesla_package,
      bamboo_package: _bamboo_package
    } do
      {:ok, view, html} = live(build_conn(), "/categories")

      assert html =~ "Categories"

      element = view |> element("[data-test-category-item='HTTP Server']") |> render()

      assert element =~ "HTTP Server"
      assert element =~ "1 packages"

      element = view |> element("[data-test-category-item='HTTP Client']") |> render()

      assert element =~ "HTTP Client"
      assert element =~ "1 packages"
    end
  end

  describe "CategoryIndexLive category toggle functionality" do
    test "expands category to show packages when toggled", %{
      bandit_package: _bandit_package,
      tesla_package: _tesla_package,
      bamboo_package: _bamboo_package
    } do
      {:ok, view, _html} = live(build_conn(), "/categories")

      refute has_element?(view, "[data-test-package-link='bandit']")

      view
      |> element("[data-test-toggle-category='HTTP Server']")
      |> render_click()

      assert has_element?(view, "[data-test-package-link='bandit']")

      view
      |> element("[data-test-toggle-category='HTTP Server']")
      |> render_click()

      refute has_element?(view, "[data-test-package-name='bandit']")
    end
  end
end
