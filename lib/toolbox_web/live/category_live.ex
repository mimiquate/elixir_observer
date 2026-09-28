defmodule ToolboxWeb.CategoryLive do
  use ToolboxWeb, :live_view
  alias Toolbox.Packages

  defmodule CategoryNotFoundError do
    defexception [:message, plug_status: 404]
  end

  def mount(%{"permalink" => permalink}, _session, socket) do
    category =
      case Packages.get_category_by_permalink(permalink) do
        nil -> raise CategoryNotFoundError, "category with permalink #{permalink} not found"
        category -> category
      end

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
