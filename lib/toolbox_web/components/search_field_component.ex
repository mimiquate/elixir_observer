defmodule ToolboxWeb.SearchFieldComponent do
  use ToolboxWeb, :live_component

  attr :autofocus, :boolean, default: false

  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={nil}
        phx-submit="search"
        phx-target={@myself}
        class="flex border rounded dark:bg-zinc-800"
      >
        <input
          type="search"
          name="term"
          placeholder="Find packages"
          class="grow border-0 focus:ring-0 bg-transparent dark:text-white"
          required
          autofocus={@autofocus}
          autocapitalize="off"
        />
        <button class="p-2">
          <.icon name="hero-magnifying-glass" />
        </button>
      </.form>
    </div>
    """
  end

  def handle_event("search", %{"term" => term}, socket) do
    {:noreply, redirect(socket, to: ~p"/searches/#{term}")}
  end
end
