defmodule ToolboxWeb.Components.Icons.BookmarkIcon do
  use Phoenix.Component

  attr :class, :string, default: nil

  def bookmark_icon(assigns) do
    ~H"""
    <svg
      width="20"
      height="20"
      viewBox="0 0 20 20"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      class={"#{@class}"}
    >
      <mask id="mask0_2433_71528" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="0" y="0" width="20" height="20">
        <rect width="20" height="20" fill="#D9D9D9"/>
      </mask>
      <g mask="url(#mask0_2433_71528)">
        <path d="M5.41797 16.3753V4.75678C5.41797 4.38164 5.54748 4.06456 5.80651 3.80553C6.06554 3.54651 6.38262 3.41699 6.75776 3.41699H13.2448C13.62 3.41699 13.9371 3.54651 14.1961 3.80553C14.4551 4.06456 14.5846 4.38164 14.5846 4.75678V16.3753L10.0013 14.5516L5.41797 16.3753ZM6.5013 14.7712L10.0013 13.3753L13.5013 14.7712V4.75678C13.5013 4.69262 13.4746 4.63387 13.4211 4.58053C13.3678 4.52706 13.309 4.50033 13.2448 4.50033H6.75776C6.69359 4.50033 6.63484 4.52706 6.58151 4.58053C6.52804 4.63387 6.5013 4.69262 6.5013 4.75678V14.7712Z" fill="#975EC9"/>
      </g>
    </svg>
    """
  end
end

