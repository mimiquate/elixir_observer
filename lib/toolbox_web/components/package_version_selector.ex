defmodule ToolboxWeb.Components.PackageVersionSelector do
  use Phoenix.Component

  @doc """
  Renders a version selector for a package.

  ## Examples

      <.package_version_selector
        versions={@package.versions}
        current_version={@version.version}
        latest_stable_version={@package.latest_stable_version}
      />
  """
  attr :versions, :list, required: true, doc: "List of tuples containing version and retirement status"
  attr :current_version, :string, required: true, doc: "Currently selected version"
  attr :latest_stable_version, :string, required: true, doc: "Latest stable version of the package"

  def package_version_selector(assigns) do
    ~H"""
    <form phx-change="version-change">
      <select name="version" class="border border-stroke rounded dark:bg-surface-alt sm:w-62 sm:text-[16px]">
        <option
          :for={{version, is_retired?} <- @versions}
          value={version}
          selected={version == @current_version}
        >
          <%= if is_retired? do %>
            {version} (Retired)
          <% else %>
            {version} {if @latest_stable_version == version, do: "(Last stable)"}
          <% end %>
        </option>
      </select>
    </form>
    """
  end
end
