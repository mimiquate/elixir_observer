defmodule ToolboxWeb.HomeLive do
  use ToolboxWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Home", disable_search: true)}
  end
end
