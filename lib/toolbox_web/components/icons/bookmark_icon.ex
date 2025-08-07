defmodule ToolboxWeb.Components.Icons.BookmarkIcon do
  use Phoenix.Component

  attr :class, :string, default: nil

  def bookmark_icon(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 19" class={"fill-accent #{@class}"}>
      <path
        class="cls-1"
        d="M0,19.06V1.81c0-.51.17-.93.52-1.28.35-.35.78-.52,1.28-.52h12.38c.51,0,.93.18,1.28.52.35.35.52.78.52,1.28v17.25l-8-2.79L0,19.06ZM1.5,16.76l6.5-2.15,6.5,2.15V1.81c0-.08-.03-.15-.1-.21-.06-.06-.13-.1-.21-.1H1.81c-.08,0-.15.03-.21.1-.06.06-.1.13-.1.21v14.95Z"
      />
    </svg>
    """
  end
end
