defmodule ToolboxWeb.AssignCurrentUser do
  import Phoenix.Component
  alias Toolbox.Users

  def on_mount(:default, _params, session, socket) do
    current_user = Users.get_user(session["user_id"])
    {:cont, assign(socket, :current_user, current_user)}
  end
end
