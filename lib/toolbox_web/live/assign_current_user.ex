defmodule ToolboxWeb.AssignCurrentUser do
  import Phoenix.Component

  def on_mount(:default, _params, session, socket) do
    {:cont, assign(socket, :current_user, session["user"])}
  end
end
