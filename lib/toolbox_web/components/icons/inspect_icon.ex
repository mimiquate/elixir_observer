defmodule ToolboxWeb.Components.Icons.InspectIcon do
  use Phoenix.Component

  attr :id, :string, default: nil
  attr :class, :string, default: nil

  def inspect_icon(assigns) do
    ~H"""
    <svg
      id={@id}
      class={@class}
      width="32"
      height="32"
      viewBox="0 0 32 32"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <rect width="32" height="32" fill="#FCFDFD" />
      <g>
        <rect width="19" height="19" fill="white" transform="translate(6.5 6.5)" />
        <path
          d="M12.334 22L6.83398 16.5L12.334 11L13.6402 12.3063L9.42357 16.5229L13.6173 20.7167L12.334 22ZM19.6673 22L18.3611 20.6938L22.5777 16.4771L18.384 12.2833L19.6673 11L25.1673 16.5L19.6673 22Z"
          fill="#8956B7"
        />
      </g>
    </svg>
    """
  end
end
