defmodule ToolboxWeb.ProfileLive do
  use ToolboxWeb, :live_view
  alias Toolbox.Packages

  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_user]

    if current_user do
      packages = Packages.list_user_followed_packages(current_user.id)

      {
        :ok,
        assign(
          socket,
          page_title: "Profile",
          search_term: "",
          packages: packages
        )
      }
    else
      {
        :ok,
        socket
        |> put_flash(:error, "You must be logged in to view your profile")
        |> redirect(to: ~p"/")
      }
    end
  end

  def handle_info({:hide_dropdown, component_id}, socket) do
    send_update(ToolboxWeb.SearchFieldComponent, id: component_id.cid, show_dropdown: false)
    {:noreply, socket}
  end
end
