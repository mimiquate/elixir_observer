defmodule ToolboxWeb.SearchFieldComponent do
  use ToolboxWeb, :live_component

  attr :autofocus, :boolean, default: false

  def render(assigns) do
    ~H"""
    <div class="sm:w-[489px]">
      <.form
        for={nil}
        phx-submit="search"
        phx-target={@myself}
        class="flex h-[36px] px-3 py-2 justify-between items-center rounded-[6px] border border-black bg-[#1D1D1D]"
      >
        <input
          type="search"
          name="term"
          placeholder="Find packages"
          class="grow border-0 focus:ring-0 bg-transparent text-white placeholder:text-gray-400"
          required
          autofocus={@autofocus}
          autocapitalize="off"
        />
        <button type="submit" class="flex items-center justify-center">
          <.icon name="hero-magnifying-glass" class="h-5 w-5 text-gray-400" />
        </button>
      </.form>
    </div>
    """
  end

  def handle_event("search", %{"term" => term}, socket) do
    {:noreply, redirect(socket, to: ~p"/searches/#{term}")}
  end
end
