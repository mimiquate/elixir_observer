defmodule ToolboxWeb.HelperComponents do
  use Phoenix.Component

  def user_link(assigns) do
    ~H"""
    <.link href={"https://hex.pm/users/#{@username}"} target="_blank">
      {@username}
    </.link>
    """
  end
end
