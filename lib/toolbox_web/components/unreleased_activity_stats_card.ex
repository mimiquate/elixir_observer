defmodule ToolboxWeb.Components.UnreleasedActivityStatsCard do
  use ToolboxWeb, :html

  import ToolboxWeb.Components.StatsCard
  import ToolboxWeb.Components.Icons.ChangelogIcon

  attr :class, :string, default: ""
  attr :package, :map, required: true

  def unreleased_activity_stats_card(assigns) do
    ~H"""
    <.stats_card class={@class} title="Unreleased Activity">
      <:icon>
        <.changelog_icon class="w-6 dark:fill-secondary-text" />
      </:icon>
      <div class="flex items-center" {test_attrs(unreleased_activity_content: true)}>
        <%= if @package.activity do %>
          <%= if last_tag_match_latest_stable_version(@package) do %>
            <.link
              class="flex text-accent"
              href={"#{@package.github_repo_url}/compare/#{@package.activity.last_tag}...HEAD"}
              target="_blank"
              {test_attrs(unreleased_activity_link: true)}
            >
              <%= if @package.activity.last_tag_behind_by == 0 do %>
                <span class="text-[12px] sm:text-[18px]/[48px]">
                  Up to date
                </span>
              <% else %>
                <h3 class="text-[20px] sm:text-[32px] font-semibold">
                  {humanized_number(@package.activity.last_tag_behind_by)}
                </h3>
                <span class="text-[10px] sm:text-[14px] self-center ml-2">
                  commits
                </span>
              <% end %>
            </.link>
          <% else %>
            <span class="text-[12px] sm:text-[18px]/[48px]">
              Unknown
            </span>
          <% end %>
        <% else %>
          -
        <% end %>
      </div>
    </.stats_card>
    """
  end

  defp last_tag_match_latest_stable_version(package) do
    String.replace(package.activity.last_tag || "", "v", "") == package.latest_stable_version
  end
end
