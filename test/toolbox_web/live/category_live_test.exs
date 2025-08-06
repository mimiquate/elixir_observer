defmodule ToolboxWeb.CategoryLiveTest do
  use ToolboxWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias Toolbox.{Category, Packages}

  setup do
    category = Category.find_by_name("HTTP Server")

    {:ok, bandit_package} =
      Packages.create_package(%{
        name: "bandit",
        description: "A pure Elixir HTTP server",
        category: category
      })

    {:ok, cowboy_package} =
      Packages.create_package(%{
        name: "cowboy",
        description: "Small, fast, modular HTTP server",
        category: category
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
        package_id: cowboy_package.id,
        data: %{
          "meta" => %{"description" => "Small, fast, modular HTTP server"},
          "downloads" => %{"recent" => 2000},
          "latest_version" => "2.0.0"
        }
      })

    %{
      category: category,
      bandit_package: bandit_package,
      cowboy_package: cowboy_package
    }
  end

  describe "CategoryLive page rendering" do
    test "renders category page with packages", %{
      category: category,
      bandit_package: bandit_package,
      cowboy_package: cowboy_package
    } do
      {:ok, view, html} = live(build_conn(), "/categories/#{category.permalink}")

      assert page_title(view) =~ category.name
      assert html =~ category.name
      assert has_element?(view, "[data-test-package-link='#{bandit_package.name}']")
      assert has_element?(view, "[data-test-package-link='#{cowboy_package.name}']")
    end
  end
end
