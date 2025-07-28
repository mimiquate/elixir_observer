defmodule ToolboxWeb.AboutLive do
  use ToolboxWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "About", show_mobile_menu: false),
     layout: {ToolboxWeb.Layouts, :home}}
  end

  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :show_mobile_menu, !socket.assigns.show_mobile_menu)}
  end
end
