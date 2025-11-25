defmodule ToolboxWeb.Components.Icons.InspectIcon do
  use Phoenix.Component

  attr :class, :string, default: nil

  def inspect_icon(assigns) do
    ~H"""
    <svg
      viewBox="0 0 20 20"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      class={"fill-accent dark:fill-secondary-text #{@class}"}
    >
      <g clip-path="url(#clip0_2269_5011)">
        <path d="M6.3335 16L0.833496 10.5L6.3335 5L7.63975 6.30625L3.42308 10.5229L7.61683 14.7167L6.3335 16ZM13.6668 16L12.3606 14.6938L16.5772 10.4771L12.3835 6.28333L13.6668 5L19.1668 10.5L13.6668 16Z" />
      </g>
      <defs>
        <clipPath>
          <rect width="19" height="19" transform="translate(0.5 0.5)" />
        </clipPath>
      </defs>
    </svg>
    """
  end
end
