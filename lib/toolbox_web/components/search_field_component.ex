defmodule ToolboxWeb.SearchFieldComponent do
  use ToolboxWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.form for={nil} phx-submit="search" phx-target={@myself}>
        <input type="search" name="term" placeholder="Search for packages" class="dark:text-black" />
      </.form>
    </div>
    """
  end

  def handle_event("search", %{"term" => term}, socket) do
    {:noreply, redirect(socket, to: ~p"/searches/#{term}")}
  end
end
