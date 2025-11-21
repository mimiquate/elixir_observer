defmodule ToolboxWeb.Components.PackageList do
  use ToolboxWeb, :html

  use ToolboxWeb, :verified_routes

  import ToolboxWeb.Components.Icons.StarIcon
  import ToolboxWeb.Components.Icons.DownloadIcon
  import ToolboxWeb.Components.Icons.BookmarkIcon

  attr :packages, :list, required: true
  attr :highlight_term, :string, default: nil
  attr :show_category, :boolean, default: true

  def package_list(assigns) do
    ~H"""
    <ul {test_attrs(packages_list: true)}>
      <li
        :for={package <- @packages}
        class="mt-5 py-3 px-5 flex flex-col md:flex-row md:justify-between bg-surface rounded-md border border-stroke"
        {test_attrs(package_item: package.name)}
      >
        <div>
          <div class="flex items-center">
            <.link
              navigate={~p"/packages/#{package.name}"}
              class="text-[14px] sm:text-[18px] hover:underline"
              {test_attrs(package_link: package.name)}
            >
              {package.name}
            </.link>
            <span
              class="ml-4 text-[16px] sm:text-[18px] text-secondary-text"
              {test_attrs(version: package.latest_hexpm_snapshot.data["latest_stable_version"])}
            >
              {package.latest_hexpm_snapshot.data["latest_stable_version"]}
            </span>

            <span
              :if={@highlight_term && package.name == @highlight_term}
              class="hidden sm:block text-sm ml-4 py-[2px] px-3 rounded-full bg-chip-bg-exact-match text-white"
              {test_attrs(exact_match: package.name)}
            >
              Exact match
            </span>
          </div>

          <p
            class="mt-2 sm:mt-1 text-[12px] sm:text-[16px] text-secondary-text"
            {test_attrs(package_description: true)}
          >
            {package.description}
          </p>

          <.link
            :if={@show_category && package.category}
            navigate={~p"/categories/#{package.category.permalink}"}
            class="flex items-center mt-2 sm:mt-1 cursor-pointer"
          >
            <.bookmark_icon class="w-[14px] h-[17px]" />

            <span class="text-[14px] sm:text-[16px] ml-2 sm:ml-3 text-accent hover:underline">
              {package.category.name}
            </span>
          </.link>

          <div class="flex items-center mt-2 sm:hidden">
            <span
              :if={@highlight_term && package.name == @highlight_term}
              class="text-[12px] py-[2px] mr-4 px-3 rounded-full border-[0.5px] border-stroke bg-chip-bg-exact-match text-white"
              {test_attrs(exact_match: package.name)}
            >
              Exact match
            </span>
            <div class="flex items-center w-[50px]">
              <.star_icon :if={package.latest_github_snapshot} class="w-4" />
              <span
                :if={package.latest_github_snapshot}
                class="ml-1 text-primary-text text-[12px] sm:text-[16px]"
                {test_attrs(package_stars_mobile: true)}
              >
                {humanized_number(package.latest_github_snapshot.data["stargazers_count"])}
              </span>
            </div>

            <div class="flex items-center ml-4 items-center justify-end sm:hidden">
              <.download_icon class="w-4" />
              <span
                class="text-[12px] text-primary-text ml-1"
                {test_attrs(package_downloads_mobile: true)}
              >
                {humanized_number(package.latest_hexpm_snapshot.data["downloads"]["recent"])}
              </span>
              <span class="text-[12px] text-secondary-text ml-1">last 90 days</span>
            </div>
          </div>
        </div>

        <div class="hidden sm:flex items-center">
          <div class="flex items-center min-w-25 justify-start">
            <div class="p-1 w-fit rounded-md">
              <.star_icon class="w-6" />
            </div>
            <span class="text-[18px] ml-2" {test_attrs(package_stars_desktop: true)}>
              <%= if package.latest_github_snapshot do %>
                {humanized_number(package.latest_github_snapshot.data["stargazers_count"])}
              <% else %>
                -
              <% end %>
            </span>
          </div>
          <div class="flex items-center min-w-25 justify-start">
            <div class="p-1 w-fit rounded-md ml-2">
              <.download_icon class="w-6" />
            </div>
            <span class="text-[18px] ml-2" {test_attrs(package_downloads_desktop: true)}>
              {humanized_number(package.latest_hexpm_snapshot.data["downloads"]["recent"])}
            </span>
          </div>
        </div>
      </li>
    </ul>
    """
  end
end
