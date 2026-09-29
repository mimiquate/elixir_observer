defmodule ToolboxWeb.Components.VersionDownloadsChart do
  use ToolboxWeb, :html

  @bar_color "bg-accent"
  @other_color "bg-primary-200"

  attr :class, :string, default: ""
  attr :version_downloads, :any, default: nil
  attr :recent_downloads, :integer, default: 0
  attr :state, :atom, default: :idle, values: [:idle, :loading, :failed]
  attr :has_more?, :boolean, default: false

  def version_downloads_chart(assigns) do
    assigns = assign(assigns, :rows, rows(assigns.version_downloads, assigns.recent_downloads))
    assigns = assign(assigns, :others_left?, Enum.any?(assigns.rows, &(&1.label == "Others")))

    ~H"""
    <div class={@class} {test_attrs(version_downloads_chart: true)}>
      <%= cond do %>
        <% @state == :failed and is_nil(@version_downloads) -> %>
          <div
            class="flex flex-col items-center justify-center py-10 gap-3"
            {test_attrs(version_downloads_failed: true)}
          >
            <p class="text-[14px] text-secondary-text text-center">
              This is taking longer than expected.
            </p>
            <button
              type="button"
              phx-click="expand_version_downloads"
              class="text-[14px] text-accent hover:underline"
            >
              Try again
            </button>
          </div>
        <% is_nil(@version_downloads) -> %>
          <div
            class="flex flex-col items-center justify-center py-10"
            {test_attrs(version_downloads_loading: true)}
          >
            <img
              src={~p"/images/spinner.svg"}
              class="w-10 h-10 animate-[spin_2s_linear_infinite]"
              alt=""
            />
            <p class="mt-4 text-[14px] text-secondary-text text-center">
              Loading visualizations for the latest version downloads. <br />
              This may take a few seconds.
            </p>
          </div>
        <% @rows == [] -> %>
          <p class="text-[14px] text-secondary-text" {test_attrs(version_downloads_empty: true)}>
            Not enough recent download data to break this down by version.
          </p>
        <% true -> %>
          <ul {test_attrs(version_downloads_list: true)}>
            <li
              :for={row <- @rows}
              class="flex items-center gap-3 py-2"
              {test_attrs(version_downloads_row: row.label)}
            >
              <span class="w-16 shrink-0 text-[14px] text-primary-text truncate">
                {row.label}
              </span>
              <div class="flex-1 h-4 sm:h-6 flex items-center bg-surface rounded-full overflow-hidden">
                <div
                  class={["h-4 sm:h-6 min-w-[4px]", row.color_class]}
                  style={"width: #{row.percent}%"}
                >
                </div>
              </div>

              <span class="w-16 shrink-0 text-[14px] text-secondary-text text-right tabular-nums">
                {humanized_number(row.downloads)}
              </span>
            </li>
          </ul>

          <div class="flex justify-center pt-2">
            <%= cond do %>
              <% @state == :failed -> %>
                <div
                  class="flex items-center gap-2 py-2"
                  {test_attrs(version_downloads_more_failed: true)}
                >
                  <span class="text-[14px] text-secondary-text">Couldn't load more.</span>
                  <button
                    type="button"
                    phx-click="show_more_version_downloads"
                    class="text-[14px] text-accent hover:underline"
                  >
                    Try again
                  </button>
                </div>
              <% @state == :loading -> %>
                <div
                  class="flex items-center gap-2 py-2"
                  {test_attrs(version_downloads_loading_more: true)}
                >
                  <img
                    src={~p"/images/spinner.svg"}
                    class="w-4 h-4 animate-[spin_2s_linear_infinite]"
                    alt=""
                  />
                  <span class="text-[14px] text-secondary-text">Loading more...</span>
                </div>
              <% @has_more? and @others_left? -> %>
                <button
                  type="button"
                  phx-click="show_more_version_downloads"
                  class="text-[14px] text-accent hover:underline py-2"
                  {test_attrs(version_downloads_show_more: true)}
                >
                  Show more
                </button>
              <% true -> %>
            <% end %>
          </div>
      <% end %>
    </div>
    """
  end

  defp rows(nil, _recent_downloads), do: []
  defp rows([], _recent_downloads), do: []

  defp rows(version_downloads, recent_downloads) do
    fetched_sum = Enum.sum_by(version_downloads, & &1.downloads)
    denominator = max(recent_downloads, fetched_sum)

    version_rows =
      Enum.map(version_downloads, fn v ->
        %{
          label: v.version,
          downloads: v.downloads,
          percent: share(v.downloads, denominator) * 100,
          color_class: @bar_color
        }
      end)

    other_downloads = max(denominator - fetched_sum, 0)

    if other_downloads > 0 do
      version_rows ++
        [
          %{
            label: "Others",
            downloads: other_downloads,
            percent: share(other_downloads, denominator) * 100,
            color_class: @other_color
          }
        ]
    else
      version_rows
    end
  end

  defp share(_downloads, 0), do: 0.0
  defp share(downloads, denominator), do: downloads / denominator
end
