defmodule ToolboxWeb.Components.PackageLink do
  use Phoenix.Component
  use ToolboxWeb, :verified_routes

  import ToolboxWeb.Components.Icons.ChevronIcon

  attr :href, :string, required: true
  attr :text, :string, required: true

  slot :icon, required: true

  def package_link(%{href: href} = assigns) when is_binary(href) do
    ~H"""
    <.link class="flex items-center text-[14px] text-primary-text py-2" href={@href} target="_blank">
      {render_slot(@icon)}
      <span class="sm:mt-0 mr-2">{@text}</span>
      <.chevron_icon class="w-6 ml-auto" />
    </.link>
    """
  end

  def package_link(assigns) do
    ~H"""
    <span class="flex items-center text-primary-text text-[14px] py-2">
      {render_slot(@icon)}
      <span class="sm:mt-0 mr-2">No {@text}</span>
    </span>
    """
  end
end
