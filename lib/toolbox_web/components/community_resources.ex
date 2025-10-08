defmodule ToolboxWeb.Components.CommunityResources do
  use ToolboxWeb, :html

  import ToolboxWeb.Components.Icons.ArticleIcon
  import ToolboxWeb.Components.Icons.VideoIcon

  @doc """
  Renders the "Community Resources" section for a package

  ## Examples
    <.community_resources resources={@package.community_resources} />
  """
  attr :resources, :any, required: true, doc: "The list of community resources"

  def community_resources(assigns) do
    ~H"""
    <div class="flex items-center justify-between mt-8 mb-3 sm:mb-8">
      <h2 class="text-[20px] text-primary-text sm:text-[32px] font-semibold">
        Community
      </h2>
    </div>
    <div class="bg-surface rounded py-6 px-4">
      <ul
        class="sm:col-span-2 sm:row-span-2"
        {test_attrs(resource_list: true)}
      >
        <%= for resource <- @resources do %>
          <li
            class="py-2 last:pb-0"
            {test_attrs(resource_item: true)}
          >
            <.link href={resource.url} target="_blank" {test_attrs(resource_url: resource.url)}>
              <h4
                class="flex text-[14px] text-primary-text sm:text-[16px] line-clamp-2 overflow-hidden hover:underline"
                {test_attrs(resource_title: true)}
              >
                <.marker type={resource.type} />
                <span class="ml-2">
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
          <div class="w-auto border-t-[0.5px] border-divider last:hidden"></div>
        <% end %>
      </ul>
    </div>
    """
  end

  defp marker(assigns) do
    case assigns.type do
      :video ->
        ~H"""
        <.video_icon class="w-5 dark:stroke-secondary-text" />
        """

      _ ->
        ~H"""
        <.article_icon class="w-5 dark:stroke-secondary-text" />
        """
    end
  end
end
