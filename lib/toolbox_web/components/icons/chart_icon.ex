defmodule ToolboxWeb.Components.Icons.ChartIcon do
  use Phoenix.Component

  attr :class, :string, default: nil

  def chart_icon(assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      class={"fill-accent #{@class}"}
    >
      <g>
        <path d="M2 22V2H4V22H2ZM6 17V14H16V17H6ZM6 10V7H22V10H6Z" />
      </g>
    </svg>
    """
  end
end
