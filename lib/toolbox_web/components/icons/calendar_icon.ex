defmodule ToolboxWeb.Components.Icons.CalendarIcon do
  use Phoenix.Component

  attr :class, :string, default: nil

  def calendar_icon(assigns) do
    ~H"""
    <svg
      viewBox="0 0 20 20"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      class={"stroke-accent dark:stroke-secondary-text #{@class}"}
    >
      <g>
        <path
          d="M13.5625 4.45833V2.875M6.4375 4.45833V2.875M3.07292 6.83333H16.9271M2.875 8.4515C2.875 6.77712 2.875 5.93954 3.22017 5.29988C3.53228 4.72933 4.01658 4.2719 4.604 3.99283C5.28167 3.66667 6.16833 3.66667 7.94167 3.66667H12.0583C13.8317 3.66667 14.7183 3.66667 15.396 3.99283C15.9921 4.27942 16.4758 4.737 16.7798 5.29908C17.125 5.94033 17.125 6.77792 17.125 8.45229V12.341C17.125 14.0153 17.125 14.8529 16.7798 15.4926C16.4677 16.0631 15.9834 16.5206 15.396 16.7996C14.7183 17.125 13.8317 17.125 12.0583 17.125H7.94167C6.16833 17.125 5.28167 17.125 4.604 16.7988C4.0167 16.52 3.53241 16.0628 3.22017 15.4926C2.875 14.8513 2.875 14.0138 2.875 12.3394V8.4515Z"
          stroke-width="1.1875"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </g>
    </svg>
    """
  end
end
