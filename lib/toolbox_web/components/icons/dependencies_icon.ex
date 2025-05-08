defmodule ToolboxWeb.Components.Icons.DependenciesIcon do
  use Phoenix.Component

  attr :class, :string, default: nil

  def dependencies_icon(assigns) do
    ~H"""
    <svg
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      class={"stroke-accent fill-accent dark:fill-secondary-text dark:stroke-secondary-text #{@class}"}
    >
      <g>
        <path
          d="M17.5625 1.9375V6.1875H13.3125V4.40625H9.84375V9.65625H13.3125V7.875H17.5625V12.125H13.3125V10.3438H9.84375V15.5938H13.3125V13.8125H17.5625V18.0625H13.3125V16.2812H10.0938C9.84511 16.2812 9.60648 16.1827 9.43066 16.0068C9.25485 15.831 9.15625 15.5924 9.15625 15.3438V10.3438H5.6875V12.125H1.4375V7.875H5.6875V9.65625H9.15625V4.65625C9.15625 4.43888 9.2317 4.22925 9.36816 4.0625L9.43066 3.99316C9.60648 3.81735 9.84511 3.71875 10.0938 3.71875H13.3125V1.9375H17.5625ZM14 17.375H16.875V14.5H14V17.375ZM2.125 11.4375H5V8.5625H2.125V11.4375ZM14 11.4375H16.875V8.5625H14V11.4375ZM14 5.5H16.875V2.625H14V5.5Z"
          stroke-width="0.5"
        />
      </g>
    </svg>
    """
  end
end
