defmodule ToolboxWeb.CategoryIndexLive do
  use ToolboxWeb, :live_view
  alias Toolbox.Packages

  import ToolboxWeb.Components.Icons.StarIcon
  import ToolboxWeb.Components.Icons.DownloadIcon

  def mount(_params, _session, socket) do
    categories_with_packages = Packages.get_three_packages_per_category()

    {
      :ok,
      assign(
        socket,
        page_title: "Categories",
        categories_with_packages: categories_with_packages,
        categories_count: length(categories_with_packages)
      )
    }
  end
end