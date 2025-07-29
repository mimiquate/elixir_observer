defmodule ToolboxWeb.Components.Icons.AnimatedHamburgerIcon do
  use Phoenix.Component

  attr :class, :string, default: nil
  attr :is_open, :boolean, default: false

  def animated_hamburger_icon(assigns) do
    ~H"""
    <svg
      viewBox="0 0 46 46"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      class={"stroke-accent dark:stroke-primary-text #{@class}"}
    >
      <g class="hamburger-lines">
        <path
          d="M14 17H32"
          stroke-width="1.5"
          class={[
            "transition-all duration-300 ease-in-out origin-center",
            @is_open && "rotate-45 -translate-x-[3.36px] translate-y-[3.36px]"
          ]}
        />
        <path
          d="M32 29L14 29"
          stroke-width="1.5"
          class={[
            "transition-all duration-300 ease-in-out origin-center",
            @is_open && "-rotate-45 -translate-x-[3.36px] -translate-y-[5.36px]"
          ]}
        />
      </g>
    </svg>
    """
  end
end
