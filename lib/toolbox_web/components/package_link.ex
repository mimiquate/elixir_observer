defmodule ToolboxWeb.Components.PackageLink do
  use Phoenix.Component
  use ToolboxWeb, :verified_routes

  attr :href, :string, required: true
  attr :icon_path, :string, required: true
  attr :text, :string, required: true

  def package_link(assigns) do
    ~H"""
    <.link class="flex items-center text-[14px] py-2" href={@href} target="_blank">
      <img src={@icon_path} class="mr-2 sm:w-4" />
      <span class="sm:mt-0 mr-2">{@text}</span>
      <img src={~p"/images/right-chevron-icon.svg"} class="ml-auto" />
    </.link>
    """
  end
end
