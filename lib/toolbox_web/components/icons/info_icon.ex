defmodule ToolboxWeb.Components.Icons.InfoIcon do
  use Phoenix.Component

  attr :class, :string, default: nil

  def info_icon(assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      class={"fill-accent dark:fill-white #{@class}"}
    >
      <g>
        <path
          fill-rule="evenodd"
          clip-rule="evenodd"
          d="M12 2C6.47717 2 2 6.47713 2 12C2 17.5228 6.47717 22 12 22C17.5229 22 22 17.5228 22 12C22 6.47713 17.5229 2 12 2ZM12 20C7.58881 20 4.00002 16.4112 4.00002 12C4.00002 7.58877 7.58877 4.00002 12 4.00002C16.4113 4.00002 20 7.58877 20 12C20 16.4112 16.4113 20 12 20ZM13.2522 8C13.2522 8.72506 12.7243 9.25002 12.0102 9.25002C11.2671 9.25002 10.7522 8.72502 10.7522 7.98612C10.7522 7.27597 11.2811 6.75003 12.0102 6.75003C12.7243 6.75003 13.2522 7.27597 13.2522 8ZM11.0022 11H13.0022V17H11.0022V11Z"
        />
      </g>
    </svg>
    """
  end
end
