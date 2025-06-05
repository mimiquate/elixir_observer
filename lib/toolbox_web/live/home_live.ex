defmodule ToolboxWeb.HomeLive do
  use ToolboxWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket, layout: {ToolboxWeb.Layouts, :home}}
  end

  def handle_info({:hide_dropdown, component_id}, socket) do
    send_update(ToolboxWeb.SearchFieldComponent, id: component_id.cid, show_dropdown: false)
    {:noreply, socket}
  end
end
