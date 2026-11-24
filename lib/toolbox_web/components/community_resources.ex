defmodule ToolboxWeb.Components.CommunityResources do
  use ToolboxWeb, :html

  import ToolboxWeb.Components.Icons.ChevronIcon
  import ToolboxWeb.Components.Icons.CommunityIcon

  @doc """
  Renders the collapsible "Community" section for a package.

  Lists the package's community resources along with a note inviting people to
  contribute more, or an empty state linking to the wiki when there are none.

  ## Examples
    <.community_resources resources={@package.community_resources} />
  """
  attr :resources, :any, required: true, doc: "The list of community resources"

  def community_resources(assigns) do
    ~H"""
    <div
      class="md:col-span-8 bg-surface rounded-md py-6 px-4 border border-stroke"
      {test_attrs(community_section: true)}
    >
      <div class="flex justify-between items-center w-full">
        <h3 class="flex items-center gap-2 text-[20px] text-primary-text sm:text-[24px] font-medium">
          <.community_icon class="w-5 h-5 sm:w-6 sm:h-6" /> Community
        </h3>
      </div>

      <div
        class="flex items-center justify-between gap-3 cursor-pointer mt-4"
        phx-click={
          JS.toggle(
            to: "#community-content",
            in:
              {"transition-all ease-out duration-300", "hidden opacity-0 max-h-0",
               "block opacity-100 max-h-[20000px]"},
            out:
              {"transition-all ease-in duration-200", "block opacity-100 max-h-[20000px]",
               "hidden opacity-0 max-h-0"}
          )
          |> JS.toggle_class("rotate-90", to: "#community-chevron")
          |> JS.toggle_class("-rotate-90", to: "#community-chevron")
        }
      >
        <p class="text-[12px] sm:text-[14px] text-secondary-text">
          Explore community content related to this package, including articles, videos, tutorials, and other resources shared by developers.
        </p>
        <.chevron_icon
          id="community-chevron"
          class="w-6 shrink-0 rotate-90 transform transition-transform duration-300"
        />
      </div>

      <div id="community-content" class="hidden opacity-0 max-h-0 transition-all mt-4">
        <div class="bg-surface-alt rounded-md border border-stroke p-3 sm:p-5">
          <%= if Enum.any?(@resources) do %>
            <.resource_list resources={@resources} />
          <% else %>
            <.empty_state />
          <% end %>
        </div>
        <p
          :if={Enum.any?(@resources)}
          class="text-[12px] sm:text-[14px] text-secondary-text mt-4 sm:mt-6"
          {test_attrs(community_contribute_note: true)}
        >
          This space grows with the community.
          <a
            class="underline text-accent"
            href={wiki_url()}
          >Contribute</a>
          useful links, guides, or resources to help others explore and learn more about this package.
        </p>
      </div>
    </div>
    """
  end

  defp resource_list(assigns) do
    ~H"""
    <ul class="max-h-[550px] overflow-y-auto show-scrollbar" {test_attrs(resource_list: true)}>
      <%= for resource <- @resources do %>
        <li {test_attrs(resource_item: true)}>
          <.link
            href={resource.url}
            target="_blank"
            {test_attrs(resource_url: resource.url)}
            class="flex items-center text-[14px] text-primary-text sm:text-[16px] whitespace-nowrap"
          >
            <.marker type={resource.type} />
            <h4 class="ml-2 truncate hover:underline" {test_attrs(resource_title: true)}>
              {resource.title}
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

  defp empty_state(assigns) do
    ~H"""
    <div class="flex justify-center" {test_attrs(community_section_empty: true)}>
      <div class="p-3 sm:p-5 flex flex-col items-center">
        <img src={~p"/images/empty-state-figure-alt.png"} />
        <h4 class="text-primary-text text-[14px] sm:text-[18px] mt-3">
          Looks like this space is still empty… Want to be the first to contribute?
        </h4>
        <p class="text-secondary-text text-[12px] sm:text-[16px]">
          Share an article, talk, or podcast by <a
            class="underline"
            href={wiki_url()}
          >adding resources to this package</a>.
        </p>
      </div>
    </div>
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

  defp wiki_url do
    "https://github.com/mimiquate/elixir_observer/wiki/%F0%9F%A7%A9-Community-Resources"
  end
end
