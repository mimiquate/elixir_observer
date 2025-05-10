defmodule ToolboxWeb.Components.Icons.ChangelogIcon do
  use Phoenix.Component

  attr :class, :string, default: nil

  def changelog_icon(assigns) do
    ~H"""
    <svg
      viewBox="0 0 21 18"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      class={"fill-accent #{@class}"}
    >
      <g>
        <path
          id="Vector"
          d="M12 0C9.61305 0 7.32387 0.948211 5.63604 2.63604C3.94821 4.32387 3 6.61305 3 9H0L4 13L8 9H5C5 5.13 8.13 2 12 2C15.87 2 19 5.13 19 9C19 12.87 15.87 16 12 16C10.07 16 8.32 15.21 7.06 13.94L5.64 15.36C6.47328 16.1982 7.46433 16.863 8.55594 17.3162C9.64754 17.7693 10.8181 18.0017 12 18C14.3869 18 16.6761 17.0518 18.364 15.364C20.0518 13.6761 21 11.3869 21 9C21 6.61305 20.0518 4.32387 18.364 2.63604C16.6761 0.948211 14.3869 3.55683e-08 12 0ZM11 5V10L15.25 12.52L16.02 11.24L12.5 9.15V5H11Z"
        />
      </g>
    </svg>
    """
  end
end
