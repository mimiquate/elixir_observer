defmodule ToolboxWeb.Components.PackageResource do
  use Phoenix.Component

  import ToolboxWeb.Components.Icons.ChevronIcon

  attr :href, :string, required: true
  attr :class, :string, default: ""
  slot :icon
  slot :text

  def package_resource(%{href: href} = assigns) when is_binary(href) do
    ~H"""
    <.link
      href={@href}
      target="_blank"
      class={"flex items-center px-3 py-2 sm:px-5 sm:py-3 rounded border border-stroke bg-surface dark:bg-surface-alt #{@class}"}
    >
      <div class="flex items-center cursor-pointer">
        <div class="flex-shrink-0">
          {render_slot(@icon)}
        </div>
        <div class="ml-2">
          <span class="text-primary-text text-[16px] sm:text-[18px]">
            {render_slot(@text)}
          </span>
        </div>
      </div>
      <div class="flex-1"></div>
      <div class="flex-shrink-0 cursor-pointer">
        <.chevron_icon class="w-6" />
      </div>
    </.link>
    """
  end

  def package_resource(assigns) do
    ~H"""
    <div class={"flex items-center px-3 py-2 sm:px-5 sm:py-3 rounded border border-stroke bg-surface dark:bg-surface-alt #{@class}"}>
      <div class="flex items-center flex-1">
        <div class="flex-shrink-0">
          {render_slot(@icon)}
        </div>
        <div class="ml-2">
          <span class="text-primary-text text-[16px] sm:text-[18px]">
            {render_slot(@text)}
          </span>
        </div>
      </div>
    </div>
    """
  end
end
