defmodule ToolboxWeb.HomeLive do
  use ToolboxWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Home", disable_search: true)}
  end

  def handle_event("logout", _params, socket) do
    {:noreply,
     socket
     |> redirect(to: ~p"/auth/logout")}
  end
end
