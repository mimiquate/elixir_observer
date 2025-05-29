defmodule ToolboxWeb.SearchFieldComponent do
  use ToolboxWeb, :live_component

  attr :class, :string, default: ""
  attr :autofocus, :boolean, default: false

  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={nil}
        phx-submit="search"
        phx-target={@myself}
        class={"flex h-[40px] px-3 py-2 justify-between items-center rounded-[6px] sm:border border-surface-alt focus-within:border-secondary-text bg-surface #{@class}"}
      >
        <input
          type="search"
          name="term"
          placeholder="Find packages"
          class="grow border-0 focus:ring-0 bg-transparent placeholder:text-secondary-text"
          required
          autofocus={@autofocus}
          autocomplete="off"
          autocapitalize="off"
        />
        <button type="submit" class="flex items-center justify-center">
          <.icon name="hero-magnifying-glass" class="h-5 w-5 text-secondary-text" />
        </button>
      </.form>
    </div>
    """
  end

  def handle_event("search", %{"term" => term}, socket) do
    term = String.trim(term)
    {:noreply, redirect(socket, to: ~p"/searches/#{term}")}
  end
end
