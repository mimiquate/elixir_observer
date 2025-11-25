defmodule ToolboxWeb.Components.Icons.ChevronIcon do
  use Phoenix.Component

  attr :id, :string, default: nil
  attr :class, :string, default: nil

  def chevron_icon(assigns) do
    ~H"""
    <svg
      viewBox="0 0 20 20"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      id={@id}
      class={"fill-primary-text dark:fill-secondary-text #{@class}"}
    >
      <g>
        <path d="M10.5003 10L6.66699 6.16667L7.83366 5L12.8337 10L7.83366 15L6.66699 13.8333L10.5003 10Z" />
      </g>
    </svg>
    """
  end
end
