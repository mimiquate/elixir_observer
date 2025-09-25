defmodule ToolboxWeb.Components.VersionDistribution do
  use ToolboxWeb, :html

  attr :versions_downloads, :any, required: true
  attr :package, :map, required: true

  def version_distribution(assigns) do
    ~H"""
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Chart -->
      <div class="bg-surface rounded-md border border-stroke p-4">
        <.async_result :let={versions_downloads} assign={@versions_downloads}>
          <:loading>
            <div class="flex items-center justify-center py-12">
              <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-accent"></div>
              <span class="ml-3 text-secondary-text">Loading chart...</span>
            </div>
          </:loading>
          <:failed :let={_failure}>
            <div class="flex items-center justify-center py-12">
              <span class="text-red-500">Failed to load chart data</span>
            </div>
          </:failed>
          <h3 class="text-[16px] font-medium text-primary-text mb-4">Download Distribution</h3>
          <%= if Enum.any?(versions_downloads) do %>
            <% total_downloads = Enum.sum(Enum.map(versions_downloads, & &1.download_sum)) %>
            <% grand_total = @package.recent_downloads %>
            <% filtered_versions = Enum.filter(versions_downloads, fn v -> (v.download_sum / grand_total) >= 0.01 end) |> Enum.take(9) %>
            <% small_versions_sum = Enum.reduce(versions_downloads, 0, fn v, acc ->
              if (v.download_sum / grand_total) < 0.01, do: acc + v.download_sum, else: acc
            end) %>
            <% other_downloads = (@package.recent_downloads - total_downloads) + small_versions_sum %>
            <% all_data = filtered_versions ++ if(other_downloads > 0, do: [%{version: "Other", download_sum: other_downloads}], else: []) %>

            <!-- Simple horizontal bar chart -->
            <div class="space-y-3">
              <%= for {data, index} <- Enum.with_index(all_data) do %>
                <% percentage = if grand_total > 0, do: (data.download_sum / grand_total) * 100, else: 0 %>

                <div class="flex items-center gap-3">
                  <div class="w-16 text-xs font-mono text-secondary-text truncate">
                    {data.version}
                  </div>
                  <div class="flex-1 bg-surface-alt rounded-full h-6 relative overflow-hidden">
                    <div
                      class="h-full rounded-full transition-all duration-500 bg-purple-500"
                      style={"width: #{percentage}%"}
                    >
                    </div>
                  </div>
                  <div class="w-24 text-xs text-secondary-text text-right">
                    {humanized_number(data.download_sum)}
                  </div>
                </div>
              <% end %>
            </div>
          <% else %>
            <div class="flex items-center justify-center py-12">
              <span class="text-secondary-text">No download data available</span>
            </div>
          <% end %>
        </.async_result>
      </div>

      <!-- Table -->
      <div class="bg-surface rounded-md border border-stroke overflow-hidden">
        <.async_result :let={versions_downloads} assign={@versions_downloads}>
          <:loading>
            <div class="flex items-center justify-center py-12">
              <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-accent"></div>
              <span class="ml-3 text-secondary-text">Loading download data...</span>
            </div>
          </:loading>
          <:failed :let={_failure}>
            <div class="flex items-center justify-center py-12">
              <span class="text-red-500">Failed to load download data</span>
            </div>
          </:failed>
          <div class="max-h-96 overflow-y-auto scrollbar-thin scrollbar-thumb-surface-alt scrollbar-track-surface border-t border-divider">
            <table class="w-full">
              <thead class="bg-surface-alt border-b border-stroke sticky top-0 z-10">
                <tr>
                  <th class="px-4 py-3 text-left text-[14px] font-medium text-secondary-text">Version</th>
                  <th class="px-4 py-3 text-left text-[14px] font-medium text-secondary-text">Downloads (90 days)</th>
                  <th class="px-4 py-3 text-left text-[14px] font-medium text-secondary-text">Released</th>
                </tr>
              </thead>
              <tbody>
                <%= for {version_data, index} <- Enum.with_index(versions_downloads) do %>
                  <tr class={["hover:bg-surface-alt", if(rem(index, 2) == 0, do: "bg-surface", else: "bg-surface-alt")]}>
                    <td class="px-4 py-3">
                      <.link
                        navigate={~p"/packages/#{@package.name}/#{version_data.version}"}
                        class="text-accent hover:underline font-mono text-[14px] sm:text-[16px]"
                      >
                        {version_data.version}
                      </.link>
                    </td>
                    <td class="px-4 py-3">
                      <span class="text-primary-text text-[14px] sm:text-[16px] font-medium">
                        {humanized_number(version_data.download_sum)}
                      </span>
                    </td>
                    <td class="px-4 py-3">
                      <span class="text-secondary-text text-[14px] sm:text-[16px]">
                        {humanized_datetime(version_data.inserted_at)}
                      </span>
                    </td>
                  </tr>
                <% end %>
                <% versions_sum = Enum.sum(Enum.map(versions_downloads, & &1.download_sum)) %>
                <% other_downloads = @package.recent_downloads - versions_sum %>
                <tr class="border-t-2 border-stroke bg-surface-alt">
                  <td class="px-4 py-3">
                    <span class="text-secondary-text text-[14px] sm:text-[16px] font-medium italic">
                      Other versions
                    </span>
                  </td>
                  <td class="px-4 py-3">
                    <span class="text-primary-text text-[14px] sm:text-[16px] font-medium">
                      {humanized_number(other_downloads)}
                    </span>
                  </td>
                  <td class="px-4 py-3">
                    <span class="text-secondary-text text-[14px] sm:text-[16px]">
                      -
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <!-- Scroll indicator -->
          <div class="flex justify-center py-2 bg-surface-alt border-t border-stroke">
            <div class="flex items-center text-xs text-secondary-text">
              <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3" />
              </svg>
              Scroll for more versions
            </div>
          </div>
        </.async_result>
      </div>
    </div>
    """
  end
end
