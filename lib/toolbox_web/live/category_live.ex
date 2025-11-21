defmodule ToolboxWeb.CategoryLive do
  use ToolboxWeb, :live_view
  alias Toolbox.Packages

  def mount(%{"permalink" => permalink}, _session, socket) do
    category = Packages.get_category_by_permalink!(permalink)
    packages = Packages.list_packages_from_category(category)

    {
      :ok,
      assign(
        socket,
        page_title: "#{category.name}",
        search_term: "",
        category: category,
        packages: packages
      )
    }
  end

  def handle_info({:hide_dropdown, component_id}, socket) do
    send_update(ToolboxWeb.SearchFieldComponent, id: component_id.cid, show_dropdown: false)
    {:noreply, socket}
  end
end
