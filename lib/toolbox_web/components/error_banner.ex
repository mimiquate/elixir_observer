defmodule ToolboxWeb.Components.ErrorBanner do
  use Phoenix.Component

  import ToolboxWeb.Components.Icons.ErrorCircleIcon

  @doc """
  Renders an error banner with an icon, a main text and an optional message below it.

  ## Examples

      <.error_banner>
        All versions are retired
      </.error_banner>

      <.error_banner message="Please use another package">
        Version 1.0.0 was retired. Reason: deprecated
      </.error_banner>
  """
  attr :class, :string, default: nil
  attr :message, :string, default: nil

  slot :inner_block, required: true

  def error_banner(assigns) do
    ~H"""
    <div class={["flex items-start rounded bg-error-200 px-3 py-2 sm:px-5 sm:py-3", @class]}>
      <.error_circle_icon class="w-6 shrink-0" />
      <div class="ml-2">
        <p class="text-[14px] text-grey-900 sm:text-[18px]">
          {render_slot(@inner_block)}
        </p>
        <p :if={@message} class="text-[12px] text-grey-900 sm:text-[14px]">
          {@message}
        </p>
      </div>
    </div>
    """
  end
end
