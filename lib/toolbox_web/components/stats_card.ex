defmodule ToolboxWeb.Components.StatsCard do
  use Phoenix.Component

  attr :class, :string, default: ""
  attr :title, :string, required: true
  attr :icon_path, :string, required: true

  slot :inner_block, required: true

  def stats_card(assigns) do
    ~H"""
    <div class={"p-3 sm:px-4 sm:py-6 #{@class}"}>
      <div class="flex items-center">
        <div class="p-1 bg-surface-alt w-fit rounded-md">
          <img src={@icon_path} />
        </div>
        <h4 class="text-[12px] sm:text-[18px] ml-2">
          {@title}
        </h4>
      </div>
      <div class="mt-2 sm:mt-4">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
