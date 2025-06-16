defmodule ToolboxWeb.CategoryIndexLive do
  use ToolboxWeb, :live_view
  alias Toolbox.{Category, Packages}

  import ToolboxWeb.Components.Icons.ChevronIcon
  import ToolboxWeb.Components.Icons.StarIcon
  import ToolboxWeb.Components.Icons.DownloadIcon
  import ToolboxWeb.Components.Icons.BookmarkIcon

  def mount(_params, _session, socket) do
    categories = Category.all()

    categories_with_count =
      Enum.map(categories, fn category ->
        package_count = Packages.count_by_category(category.id)
        Map.put(category, :package_count, package_count)
      end)

    {
      :ok,
      assign(
        socket,
        page_title: "Categories",
        categories: categories_with_count,
        expanded_categories: MapSet.new(),
        category_packages: %{}
      )
    }
  end

  def handle_event("toggle_category", %{"category_id" => category_id}, socket) do
    category_id = String.to_integer(category_id)
    expanded_categories = socket.assigns.expanded_categories

    {new_expanded_categories, category_packages} =
      if MapSet.member?(expanded_categories, category_id) do
        # Collapse category
        {MapSet.delete(expanded_categories, category_id), socket.assigns.category_packages}
      else
        # Expand category - fetch packages
        category = Enum.find(socket.assigns.categories, &(&1.id == category_id))
        packages = Packages.list_packages_from_category(category) |> Enum.take(3)
        new_packages = Map.put(socket.assigns.category_packages, category_id, packages)
        {MapSet.put(expanded_categories, category_id), new_packages}
      end

    {
      :noreply,
      assign(socket,
        expanded_categories: new_expanded_categories,
        category_packages: category_packages
      )
    }
  end
end
