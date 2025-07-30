defmodule ToolboxWeb.Components.MobileMenu do
  use ToolboxWeb, :html

  import ToolboxWeb.Components.Icons.AnimatedHamburgerIcon

  attr :show, :boolean, default: false
  attr :class, :string, default: nil

  def mobile_navigation(assigns) do
    ~H"""
    <div class="block sm:hidden h-[46px]">
      <!-- Hamburger Button -->
      <button
        type="button"
        class={["relative z-[60]", @class]}
        phx-click="toggle_mobile_menu"
        aria-label={(@show && "Close menu") || "Open menu"}
      >
        <.animated_hamburger_icon class="w-[46px] h-[46px]" is_open={@show} />
      </button>
      <div
        class={[
          "fixed inset-0 z-50 transition-all duration-300 ease-in-out",
          (@show && "opacity-100 pointer-events-auto") || "opacity-0 pointer-events-none"
        ]}
        id="mobile-menu-overlay"
      >
        <div class="absolute w-full bg-background shadow-md dark:shadow-gray-800 transition-all duration-300 ease-out">
          <div class="flex flex-col h-full px-5">
            <div class="flex justify-between items-center py-3 transition-all duration-300 ease-out delay-100">
              <.link navigate="/">
                <.logo class="w-[153px]" />
              </.link>
            </div>

            <div class={[
              "flex-1 flex flex-col items-center justify-center py-12",
              (@show && "translate-y-0 opacity-100") || "-translate-y-4 opacity-0"
            ]}>
              <nav class="text-center space-y-8">
                <.link
                  navigate={~p"/about"}
                  class={[
                    "block text-[20px] font-medium text-accent dark:text-primary-text transition-all duration-300 ease-out delay-200",
                    (@show && "translate-y-0 opacity-100") || "translate-y-4 opacity-0"
                  ]}
                  phx-click="toggle_mobile_menu"
                >
                  About
                </.link>

                <.link
                  href="https://github.com/mimiquate/elixir_observer"
                  target="_blank"
                  class={[
                    "block text-[20px] font-medium text-accent dark:text-primary-text transition-all duration-300 ease-out delay-300",
                    (@show && "translate-y-0 opacity-100") || "translate-y-4 opacity-0"
                  ]}
                  phx-click="toggle_mobile_menu"
                >
                  Source
                </.link>
              </nav>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
