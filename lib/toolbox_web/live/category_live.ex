defmodule ToolboxWeb.CategoryLive do
  use ToolboxWeb, :live_view
  alias Toolbox.Packages

  import ToolboxWeb.Components.Icons.StarIcon
  import ToolboxWeb.Components.Icons.DownloadIcon

  def mount(%{"id" => id}, _session, socket) do
    id = String.to_integer(id)
    category = Packages.get_category!(id)
    packages = Packages.list_packages_from_category(category)

    {
      :ok,
      assign(
        socket,
        page_title: "#{category.name}",
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
