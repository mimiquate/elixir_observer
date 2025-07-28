defmodule ToolboxWeb.Components.PackageOwners do
  use ToolboxWeb, :live_component

  import ToolboxWeb.Components.Icons.ProfileIcon

  attr :class, :string, default: ""
  attr :owners, :list, required: true

  def mount(socket) do
    {:ok, assign(socket, show_owners_popover: false)}
  end

  def update(assigns, socket) do
    # Ensure class has a default value if not provided
    assigns = Map.put_new(assigns, :class, "")
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <div class={"mt-3 flex flex-wrap gap-2 relative #{@class}"} {test_attrs(package_owners_section: true)}>
      <.owner_chip :for={owner <- Enum.slice(@owners, 0, 4)} owner={owner} />

      <%= if length(@owners) > 4 do %>
        <div class="relative">
          <div
            class="flex justify-center items-center h-fit py-[2px] pl-[4px] pr-3 rounded-[1.5rem] border border-stroke bg-chip-bg cursor-pointer hover:bg-surface-alt transition-colors"
            phx-click="toggle_owners_popover"
            phx-click-away="hide_owners_popover"
            phx-target={@myself}
            {test_attrs(owners_show_more_button: true)}
          >
            <.profile_icon class="w-4 sm:w-8" />
            <span class="ml-1 text-[12px] sm:text-[14px] text-accent">
              + {length(@owners) - 4} owners
            </span>
          </div>

          <%= if @show_owners_popover do %>
            <div class="absolute top-full right-0 sm:left-0 z-50 mt-4" {test_attrs(owners_popover: true)}>
              <!-- Popover with integrated nozzle -->
              <div class="relative bg-surface rounded-lg border border-stroke min-w-max">
                <!-- Much larger solid nozzle/arrow pointing up to the trigger chip -->
                <div class="absolute -top-2 right-6 sm:left-6 w-0 h-0 border-l-8 border-r-8 border-b-8 border-l-transparent border-r-transparent border-b-stroke">
                </div>
                <div class="absolute -top-[6.5px] right-6 sm:left-6 w-0 h-0 border-l-8 border-r-8 border-b-8 border-l-transparent border-r-transparent border-b-surface">
                </div>

                <!-- Popover content -->
                <div class="p-3">
                  <div class="flex flex-wrap gap-2 max-w-[200px] sm:max-w-sm" {test_attrs(owners_popover_content: true)}>
                    <.owner_chip :for={owner <- Enum.drop(@owners, 4)} owner={owner} />
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # Private function component for owner chips
  defp owner_chip(assigns) do
    ~H"""
    <.user_link
      class="flex justify-center items-center h-fit py-[2px] pl-[4px] pr-3 rounded-[1.5rem] border border-stroke bg-chip-bg"
      username={@owner.username}
      {test_attrs(owner_chip: @owner.username)}
    >
      <img
        width="32px"
        height="32px"
        class="hidden sm:block rounded-full"
        src={gravatar_url(@owner.email)}
      />
      <img width="16px" height="16px" class="sm:hidden rounded-full" src={gravatar_url(@owner.email)} />
      <span class="ml-2 text-[12px] sm:text-[14px] text-accent">{@owner.username}</span>
    </.user_link>
    """
  end

  def handle_event("toggle_owners_popover", _params, socket) do
    {:noreply, assign(socket, show_owners_popover: !socket.assigns.show_owners_popover)}
  end

  def handle_event("hide_owners_popover", _params, socket) do
    {:noreply, assign(socket, show_owners_popover: false)}
  end
end
