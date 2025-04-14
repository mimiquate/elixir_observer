defmodule ToolboxWeb.HomeLive do
  use ToolboxWeb, :live_view

  def mount(_params, _session, socket) do
    {
      :ok,
      assign(socket, form: to_form(%{}))
    }
  end

  def handle_event("search", %{"term" => term}, socket) do
    {:noreply, redirect(socket, to: ~p"/searches/#{term}")}
  end
end
