defmodule ToolboxWeb.Components.LogoutButton do
  use ToolboxWeb, :live_component

  attr :class, :string, default: nil

  def render(assigns) do
    ~H"""
    <button
      phx-click="logout"
      phx-target={@myself}
      class={@class}
    >
      Logout
    </button>
    """
  end

  def handle_event("logout", _params, socket) do
    {:noreply, redirect(socket, to: ~p"/auth/logout")}
  end
end
