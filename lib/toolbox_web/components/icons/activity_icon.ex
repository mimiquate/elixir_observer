defmodule ToolboxWeb.Components.Icons.ActivityIcon do
  use Phoenix.Component

  attr :class, :string, default: nil

  def activity_icon(assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      class={"fill-accent #{@class}"}
    >
      <g>
        <path d="M7.34625 16.6538V7.34625H16.6538V16.6538H7.34625ZM8.84625 15.1538H15.1538V8.84625H8.84625V15.1538ZM3.5 16.6538V15.0385H5.1155V16.6538H3.5ZM3.5 8.9615V7.34625H5.1155V8.9615H3.5ZM7.34625 20.5V18.8845H8.9615V20.5H7.34625ZM7.34625 5.1155V3.5H8.9615V5.1155H7.34625ZM15.0385 20.5V18.8845H16.6538V20.5H15.0385ZM15.0385 5.1155V3.5H16.6538V5.1155H15.0385ZM18.8845 16.6538V15.0385H20.5V16.6538H18.8845ZM18.8845 8.9615V7.34625H20.5V8.9615H18.8845Z" />
      </g>
    </svg>
    """
  end
end
