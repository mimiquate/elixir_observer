defmodule ToolboxWeb.CategoryLiveTest do
  use ToolboxWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias Toolbox.Category

  setup do
    category = Category.find_by_name("HTTP Server")

    {:ok, package1} = create(:package, category: category)
    {:ok, package2} = create(:package, category: category)
    {:ok, _} = create(:hexpm_snapshot, package_id: package1.id)
    {:ok, _} = create(:hexpm_snapshot, package_id: package2.id)

    %{
      category: category,
      package1: package1,
      package2: package2
    }
  end

  describe "CategoryLive page rendering" do
    test "renders category page with packages", %{
      category: category,
      package1: package1,
      package2: package2
    } do
      {:ok, view, html} = live(build_conn(), "/categories/#{category.permalink}")

      assert page_title(view) =~ category.name
      assert html =~ category.name
      assert has_element?(view, data_test_attr(:package_link, package1.name))
      assert has_element?(view, data_test_attr(:package_link, package2.name))
    end
  end
end
