defmodule ToolboxWeb.HomeLive do
  use ToolboxWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket, layout: {ToolboxWeb.Layouts, :home}}
  end
end
