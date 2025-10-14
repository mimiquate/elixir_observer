defmodule ToolboxWeb.Components.CommunityResources do
  use ToolboxWeb, :html

  @doc """
  Renders the "Community Resources" section for a package

  ## Examples
    <.community_resources resources={@package.community_resources} />
  """
  attr :resources, :any, required: true, doc: "The list of community resources"

  def community_resources(assigns) do
    ~H"""
    <ul
      class="sm:col-span-2 sm:row-span-2 max-h-[253px] overflow-y-scroll show-scrollbar"
      {test_attrs(resource_list: true)}
    >
      <%= for resource <- @resources do %>
        <li {test_attrs(resource_item: true)}>
          <.link href={resource.url} target="_blank" {test_attrs(resource_url: resource.url)}>
            <h4 class="flex items-center text-[14px] text-primary-text sm:text-[16px] line-clamp-2 whitespace-nowrap">
              <.marker type={resource.type} />
              <span class="ml-2 hover:underline" {test_attrs(resource_title: true)}>
                {resource.title}
              </span>
            </h4>
          </.link>
          <div class="flex mt-1">
            <span
              class="text-[14px] text-secondary-text"
              {test_attrs(resource_description: true)}
            >
              {resource.description}
            </span>
          </div>
        </li>
        <div class="w-auto border-t-[0.5px] border-divider my-3 last:hidden"></div>
      <% end %>
    </ul>
    """
  end

  defp marker(assigns) do
    ~H"""
    <span class="flex content-center items-center text-xs rounded-full border text-accent">
      <span class="flex-none my-[2px] mx-3">
        {Phoenix.Naming.humanize(assigns.type)}
      </span>
    </span>
    """
  end
end
