defmodule ToolboxWeb.Components.PackageActivity do
  use ToolboxWeb, :html

  alias Toolbox.Packages.GitHubActivity

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
    <div class={"md:col-span-6 bg-surface rounded-md py-6 px-4 border border-stroke #{@class}"}>
      <div class="flex justify-between w-full">
        <h3 class="text-[20px] text-primary-text sm:text-[24px] font-medium mb-4 sm:mb-6">
          Activity
        </h3>

        <%= if match?(%GitHubActivity{}, @activity) do %>
          <div class="flex justify-center items-center gap 2 h-fit py-1 px-3 sm:px-5 rounded-2xl border border-accent dark:border-violet bg-white dark:bg-violet">
            <span class="text-[12px] sm:text-[16px] text-accent dark:text-primary-text">
              last year
            </span>
          </div>
        <% end %>
      </div>

      <div class="grid gap-x-2 gap-y-4 grid-cols-2 sm:grid-cols-3 sm:grid-rows-2 sm:gap-8">
        <%= if match?(%GitHubActivity{}, @activity) do %>
          <div class="order-3 p-3 sm:col-span-1 sm:row-span-1 bg-surface-alt sm:p-5 rounded-md border border-stroke">
            <h3 class="text-[16px] text-primary-text sm:text-[18px] mb-4">Pull Requests</h3>
            <div class="w-full">
              <div class="flex justify-between items-center">
                <span class="text-secondary-text text-[12px] sm:text-[16px]">Open</span>
                <span class="font-semibold text-primary-text text-[16px] sm:text-[32px]">
                  {@activity.open_pr_count}
                </span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-secondary-text text-[12px] sm:text-[16px]">Merged</span>
                <span class="font-semibold text-primary-text text-[16px] sm:text-[32px]">
                  {@activity.merged_pr_count}
                </span>
              </div>
            </div>
          </div>
          <div class="order-1 px-3 py-5 col-span-2 sm:order-2 sm:row-span-2 sm:p-5 bg-surface-alt rounded-md border border-stroke">
            <div class="flex justify-between">
              <h3 class="text-[16px] text-primary-text sm:text-[18px] mb-2">
                Latest Merged Pull Requests
              </h3>
              <.link
                :if={@github_fullname}
                class="cursor-pointer"
                href={"https://github.com/" <> @github_fullname <> "/pulls"}
                target="_blank"
              >
                <.button size={:xsmall}>
                  See all
                </.button>
              </.link>
            </div>
            <%= if Enum.any?(@activity.pull_requests) do %>
              <ul class="sm:pt-4 sm:col-span-2" sm:row-span-2>
                <%= for {pr, i} <- Enum.with_index(@activity.pull_requests) do %>
                  <li class="py-2 last:pb-0">
                    <.link href={pr["permalink"]} target="_blank">
                      <h4 class="text-[14px] text-primary-text sm:text-[16px] line-clamp-2 overflow-hidden">
                        {pr["title"]}
                      </h4>
                    </.link>
                    <div class="flex mt-1">
                      <img class="w-6 rounded-full" src={pr["mergedBy"]["avatarUrl"]} />
                      <span class="text-[14px] ml-2">{pr["mergedBy"]["login"]}</span>
                      <% {merged_at_number, merged_at_relative_label} =
                        relative_datetime(pr["mergedAt"]) %>
                      <span class="text-[14px] ml-1 sm:ml-2 text-secondary-text">
                        merged {merged_at_number} {merged_at_relative_label}
                      </span>
                    </div>
                  </li>
                  <div :if={i < 4} class="w-auto border-t-[0.5px] border-divider"></div>
                <% end %>
              </ul>
            <% else %>
              <div class="flex items-center justify-center min-h-20 sm:min-h-0 sm:h-full mt-2">
                <h2 class="text-[24px] text-primary-text font-medium h-fit">
                  No Github activity
                </h2>
              </div>
            <% end %>
          </div>
          <div class="order-2 p-3 sm:order-3 sm:col-span-1 sm:row-span-1 bg-surface-alt sm:p-5 rounded-md border border-stroke">
            <h3 class="text-[16px] text-primary-text sm:text-[18px] mb-4">Issues</h3>
            <div>
              <div class="flex justify-between items-center">
                <span class="text-secondary-text text-[12px] sm:text-[16px]">Open</span>
                <span class="font-semibold text-[16px] text-primary-text sm:text-[32px]">
                  {@activity.open_issue_count}
                </span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-secondary-text text-[12px] sm:text-[16px]">Closed</span>
                <span class="font-semibold text-[16px] text-primary-text sm:text-[32px]">
                  {@activity.closed_issue_count}
                </span>
              </div>
            </div>
          </div>
        <% else %>
          <div class="p-3 sm:p-5 sm:col-span-3 sm:row-span-2 flex flex-col items-center">
            <img src={~p"/images/error-illustration.png"} />
            <h3 class="text-primary-text sm:text-[24px] mt-3">Failed to load repo activity.</h3>
            <p class="text-secondary-text sm:text-[16px]">Please refresh in a bit</p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
