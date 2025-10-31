defmodule ToolboxWeb.CategoryIndexLive do
  use ToolboxWeb, :live_view
  alias Toolbox.{Category, Packages}

  import ToolboxWeb.Components.Icons.ChevronIcon
  import ToolboxWeb.Components.Icons.StarIcon
  import ToolboxWeb.Components.Icons.DownloadIcon
  import ToolboxWeb.Components.Icons.BookmarkIcon

  def mount(_params, _session, socket) do
    categories = Category.all()
    counts = Packages.categories_counts()

    categories_with_count =
      Enum.map(categories, fn category ->
        package_count = Map.get(counts, category, 0)
        Map.put(category, :package_count, package_count)
      end)

    {
      :ok,
      assign(
        socket,
        page_title: "Categories",
        search_term: "",
        categories: categories_with_count,
        category_packages: %{}
      )
    }
  end

  def handle_event("toggle_category", %{"category_id" => category_id}, socket) do
    category_id = String.to_integer(category_id)
    category_packages = socket.assigns.category_packages

    new_category_packages =
      if Map.has_key?(category_packages, category_id) do
        # Collapse category - remove packages
        Map.delete(category_packages, category_id)
      else
        # Expand category - fetch packages
        category = Enum.find(socket.assigns.categories, &(&1.id == category_id))
        packages = Packages.list_packages_from_category(category, 3)
        Map.put(category_packages, category_id, packages)
      end

    {
      :noreply,
      assign(socket, category_packages: new_category_packages)
    }
  end

  def handle_event("logout", _params, socket) do
    {:noreply,
     socket
     |> redirect(to: ~p"/auth/logout")}
  end
end
