defmodule ToolboxWeb.Components.MobileMenu do
  use ToolboxWeb, :html

  import ToolboxWeb.Components.Icons.InfoIcon
  import ToolboxWeb.Components.Icons.GithubIcon

  attr :show, :boolean, default: false
  attr :class, :string, default: nil

  def mobile_menu(assigns) do
    ~H"""
    <div
      class={[
        "fixed inset-0 z-50 transition-all duration-300 ease-in-out",
        (@show && "block") || "hidden",
        @class
      ]}
      id="mobile-menu-overlay"
    >
      <div class="absolute w-full bg-background">
        <div class="flex flex-col h-full px-5">
          <div class="flex justify-between items-center py-3">
            <.link navigate="/">
              <.logo class="w-[153px]" />
            </.link>
            <button type="button" class="p-2" phx-click="toggle_mobile_menu" aria-label="Close menu">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>

          <div class="flex-1 flex flex-col items-center justify-center space-y-12">
            <nav class="text-center space-y-8">
              <div>
                <h2 class="text-lg font-medium text-primary-text mb-4">Categories</h2>
              </div>

              <div>
                <.link
                  navigate={~p"/about"}
                  class="block text-lg font-medium text-primary-text"
                  phx-click="toggle_mobile_menu"
                >
                  About
                </.link>
              </div>

              <div>
                <.link
                  href="https://github.com/mimiquate/elixir_observer"
                  target="_blank"
                  class="block text-lg font-medium text-primary-text"
                  phx-click="toggle_mobile_menu"
                >
                  Source
                </.link>
              </div>
            </nav>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :class, :string, default: nil

  def hamburger_menu(assigns) do
    ~H"""
    <button
      type="button"
      class={["p-2 block sm:hidden", @class]}
      phx-click="toggle_mobile_menu"
      aria-label="Open menu"
    >
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M4 6h16M4 12h16M4 18h16"
        />
      </svg>
    </button>
    """
  end
end
