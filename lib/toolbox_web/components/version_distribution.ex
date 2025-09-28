defmodule ToolboxWeb.Components.VersionDistribution do
  use ToolboxWeb, :html

  attr :versions_downloads, :any, required: true
  attr :package, :map, required: true

  def version_distribution(assigns) do
    ~H"""
    <div class="flex items-center justify-between mt-8 mb-3 sm:mb-8">
      <h2 class="text-[20px] text-primary-text sm:text-[32px] font-semibold">
        Latest Versions Downloads (Last 90 Days)
      </h2>
    </div>

    <div class="grid grid-cols-1 gap-6">
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
    </div>
    """
  end
end
