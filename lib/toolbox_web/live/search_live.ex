defmodule ToolboxWeb.SearchLive do
  use ToolboxWeb, :live_view
  alias Toolbox.Packages

  def mount(%{"term" => term}, _session, socket) do
    {packages, more?} = Packages.search(term)

    {
      :ok,
      assign(
        socket,
        term: term,
        page_title: "\"#{term}\"",
        packages: packages,
        more?: more?
      )
    }
  end
end
