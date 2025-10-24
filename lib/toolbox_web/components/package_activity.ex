defmodule ToolboxWeb.Components.PackageActivity do
  use ToolboxWeb, :html

  @doc """
  Renders the activity section for a package.

  ## Examples

      <.package_activity activity={@package.activity} github_fullname={@package.github_fullname} />
  """
  attr :activity, :any, required: true, doc: "The GitHub activity data"
  attr :github_fullname, :string, default: nil, doc: "The GitHub repository full name"
  attr :class, :string, default: "", doc: "Additional CSS classes"

  def package_activity(assigns) do
    ~H"""
    <div
      class={"md:col-span-8 bg-surface rounded-md py-6 px-4 border border-stroke #{@class}"}
      {test_attrs(activity_section: true)}
    >
      <div class="flex justify-between w-full">
        <h3
          class="text-[20px] text-primary-text sm:text-[24px] font-medium mb-4 sm:mb-6"
          {test_attrs(activity_title: true)}
        >
          Activity
        </h3>

        <%= if @activity do %>
          <div
            class="flex justify-center items-center gap 2 h-fit py-1 px-3 sm:px-5 rounded-2xl border border-accent dark:border-violet bg-white dark:bg-violet"
            {test_attrs(last_year_badge: true)}
          >
            <span class="text-[12px] sm:text-[16px] text-accent dark:text-primary-text">
              last year
            </span>
          </div>
        <% end %>
      </div>

      <div class="grid gap-x-2 gap-y-4 grid-cols-2 sm:grid-cols-3 sm:grid-rows-2 sm:gap-8">
        <%= if @activity do %>
          <div
            class="order-3 p-3 sm:col-span-1 sm:row-span-1 bg-surface-alt sm:p-5 rounded-md border border-stroke"
            {test_attrs(pull_requests_section: true)}
          >
            <h3
              class="text-[16px] text-primary-text sm:text-[18px] mb-4"
              {test_attrs(pull_requests_title: true)}
            >
              Pull Requests
            </h3>
            <div class="w-full">
              <div class="flex justify-between items-center">
                <span class="text-secondary-text text-[12px] sm:text-[16px]">Open</span>
                <span
                  class="font-semibold text-primary-text text-[16px] sm:text-[32px]"
                  {test_attrs(open_pr_count: true)}
                >
                  {@activity.open_pr_count}
                </span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-secondary-text text-[12px] sm:text-[16px]">Merged</span>
                <span
                  class="font-semibold text-primary-text text-[16px] sm:text-[32px]"
                  {test_attrs(merged_pr_count: true)}
                >
                  {@activity.merged_pr_count}
                </span>
              </div>
            </div>
          </div>
          <div
            class="order-1 px-3 py-5 col-span-2 sm:order-2 sm:row-span-2 sm:p-5 bg-surface-alt rounded-md border border-stroke"
            {test_attrs(latest_prs_section: true)}
          >
            <div class="flex justify-between">
              <h3
                class="text-[16px] text-primary-text sm:text-[18px] mb-2"
                {test_attrs(latest_prs_title: true)}
              >
                Latest Merged Pull Requests
              </h3>
              <.link
                :if={@github_fullname}
                class="cursor-pointer"
                href={see_all_link_href(@github_fullname)}
                target="_blank"
                {test_attrs(see_all_link: true)}
              >
                <.button size={:xsmall}>
                  See all
                </.button>
              </.link>
            </div>
            <%= if Enum.any?(@activity.pull_requests) do %>
              <ul class="sm:pt-4 sm:col-span-2 sm:row-span-2" {test_attrs(pr_list: true)}>
                <%= for {pr, i} <- Enum.with_index(@activity.pull_requests) do %>
                  <li class="py-2 last:pb-0" {test_attrs(pr_item: pr.permalink)}>
                    <.link href={pr.permalink} target="_blank" {test_attrs(pr_link: true)}>
                      <h4
                        class="text-[14px] text-primary-text sm:text-[16px] line-clamp-2 overflow-hidden hover:underline"
                        {test_attrs(pr_title: true)}
                      >
                        {pr.title}
                      </h4>
                    </.link>
                    <div class="flex mt-1">
                      <img
                        class="w-6 rounded-full"
                        src={pr.merged_by_avatar_url}
                        {test_attrs(pr_avatar: true)}
                      />
                      <.link
                        href={"https://github.com/#{pr.merged_by_login}"}
                        target="_blank"
                        class="text-[14px] ml-2 hover:underline"
                        {test_attrs(pr_author: true)}
                      >
                        {pr.merged_by_login}
                      </.link>
                      <% {merged_at_number, merged_at_relative_label} =
                        relative_datetime(pr.merged_at) %>
                      <span
                        class="text-[14px] ml-1 sm:ml-2 text-secondary-text"
                        {test_attrs(pr_merged_time: true)}
                      >
                        merged {merged_at_number} {merged_at_relative_label}
                      </span>
                    </div>
                  </li>
                  <div
                    :if={i < 4}
                    class="w-auto border-t-[0.5px] border-divider"
                    {test_attrs(pr_divider: true)}
                  >
                  </div>
                <% end %>
              </ul>
            <% else %>
              <div
                class="flex items-center justify-center min-h-20 sm:min-h-0 sm:h-full mt-2"
                {test_attrs(no_activity_message: true)}
              >
                <h2 class="text-[24px] text-primary-text font-medium h-fit">
                  No Github activity
                </h2>
              </div>
            <% end %>
          </div>
          <div
            class="order-2 p-3 sm:order-3 sm:col-span-1 sm:row-span-1 bg-surface-alt sm:p-5 rounded-md border border-stroke"
            {test_attrs(issues_section: true)}
          >
            <h3
              class="text-[16px] text-primary-text sm:text-[18px] mb-4"
              {test_attrs(issues_title: true)}
            >
              Issues
            </h3>
            <div>
              <div class="flex justify-between items-center">
                <span class="text-secondary-text text-[12px] sm:text-[16px]">Open</span>
                <span
                  class="font-semibold text-[16px] text-primary-text sm:text-[32px]"
                  {test_attrs(open_issue_count: true)}
                >
                  {@activity.open_issue_count}
                </span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-secondary-text text-[12px] sm:text-[16px]">Closed</span>
                <span
                  class="font-semibold text-[16px] text-primary-text sm:text-[32px]"
                  {test_attrs(closed_issue_count: true)}
                >
                  {@activity.closed_issue_count}
                </span>
              </div>
            </div>
          </div>
        <% else %>
          <div
            class="p-3 sm:p-5 col-span-2 sm:col-span-3 sm:row-span-2 flex flex-col items-center"
            {test_attrs(error_state: true)}
          >
            <img src={~p"/images/empty-state-figure.png"} {test_attrs(error_image: true)} />
            <h3 class="text-primary-text sm:text-[24px] mt-3" {test_attrs(error_title: true)}>
              No Github Activity
            </h3>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp see_all_link_href(github_fullname) do
    one_year_ago = Date.add(Date.utc_today(), -365) |> Date.to_iso8601()

    "https://github.com/#{github_fullname}/pulls?q=is%3Apr+is%3Amerged+created%3A%3E#{one_year_ago}"
  end
end
