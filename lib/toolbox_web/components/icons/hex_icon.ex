defmodule ToolboxWeb.Components.Icons.HexIcon do
  use Phoenix.Component

  attr :class, :string, default: nil

  def hex_icon(assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      class={"fill-accent #{@class}"}
    >
      <g clip-path="url(#clip0_3820_61816)">
        <g>
          <path
            d="M16.92 3.5H7.10995L2.19995 12L7.10995 20.5H16.92L21.83 12L16.92 3.5ZM15.99 18.88H8.03995L4.06995 12L8.03995 5.12H15.99L19.96 12L15.99 18.88Z"
            fill="#975EC9"
          />
          <path d="M14.6999 7.3501H9.32989L6.63989 12.0001L9.32989 16.6501H14.6999L17.3899 12.0001L14.6999 7.3501ZM13.8399 15.1501H10.1999L8.37989 12.0001L10.1999 8.8501H13.8399L15.6599 12.0001L13.8399 15.1501Z" />
        </g>
      </g>
      <defs>
        <clipPath>
          <rect width="24" height="24" fill="white" />
        </clipPath>
      </defs>
    </svg>
    """
  end
end
