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
        <path d="M3.67541 18.8155L2.78516 17.9252L9.63891 11.0715L13.5639 14.9965L15.5352 12.758L9.61966 6.94624L3.67541 12.8905L2.78516 12.0002L9.63891 5.14648L16.3697 11.8117L20.2312 7.42148L21.2349 8.23098L17.2889 12.7347L21.3099 16.731L20.4197 17.5962L16.4447 13.6712L13.6582 16.8462L9.63891 12.8272L3.67541 18.8155Z" />
      </g>
    </svg>
    """
  end
end
