defmodule ToolboxWeb.Components.UserMenu do
  use ToolboxWeb, :live_component

  import ToolboxWeb.Components.Icons.GithubIcon

  attr :current_user, :map, default: nil

  def render(assigns) do
    ~H"""
    <div class="hidden sm:flex justify-center w-[120px]">
      <%= if @current_user do %>
        <div
          class="hidden sm:flex text-[16px] font-medium text-secondary-text hover:text-accent active:text-accent active:underline"
          id="user-dropdown"
        >
          <button class="" phx-click={JS.toggle(to: "#user-dropdown-menu", display: "flex")}>
            <img
              src={@current_user.avatar_url}
              alt={@current_user.login}
              class="h-8 rounded-full cursor-pointer"
            />
          </button>

          <div
            id="user-dropdown-menu"
            class="hidden absolute top-14 right-10 bg-background rounded-md z-50 flex flex-col"
          >
            <.link
              navigate={~p"/profile"}
              class="text-[16px] px-4 py-2 font-medium text-secondary-text hover:text-accent active:text-accent active:underline transition-all duration-300cl ease-out delay-200"
            >
              Profile
            </.link>
            <.live_component
              module={ToolboxWeb.Components.LogoutButton}
              id="desktop-logout-button"
              class="inline text-[16px] px-4 py-2 font-medium text-secondary-text hover:text-accent active:text-accent active:underline transition-all duration-300cl ease-out delay-200"
            >
              Log Out
            </.live_component>
          </div>
        </div>
      <% else %>
        <.link
          href={~p"/auth/github"}
          class="hidden sm:flex items-center py-2 px-5 bg-accent rounded-lg text-white"
        >
          <.github_icon class="mr-2 w-4 fill-white" />
          <span class="text-[16px] font-medium">Log in</span>
        </.link>
      <% end %>
    </div>
    """
  end
end
