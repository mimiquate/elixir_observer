defmodule ToolboxWeb.AboutLive do
  use ToolboxWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "About"), layout: {ToolboxWeb.Layouts, :home}}
  end
end
