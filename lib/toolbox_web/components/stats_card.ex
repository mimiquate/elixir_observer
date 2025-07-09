defmodule ToolboxWeb.Components.StatsCard do
  use Phoenix.Component

  attr :class, :string, default: ""
  attr :title, :string, required: true

  slot :icon, required: true
  slot :inner_block, required: true

  def stats_card(assigns) do
    ~H"""
    <div class={@class}>
      <div class="flex items-center basis-[fit-content]">
        {render_slot(@icon)}

        <h4 class="text-[12px] sm:text-[18px] ml-2 text-primary-text">
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
