defmodule ToolboxWeb.PageController do
  use ToolboxWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
