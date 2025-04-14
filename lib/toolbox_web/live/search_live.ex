defmodule ToolboxWeb.SearchLive do
  use ToolboxWeb, :live_view

  def mount(%{"term" => term}, _session, socket) do
    {
      :ok,
      assign(
        socket,
        term: term,
        packages: Toolbox.Packages.search(term)
      )
    }
  end
end
