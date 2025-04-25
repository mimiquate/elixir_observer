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
        packages:
          Enum.map(packages, fn p ->
            # Fix N+1 Query
            {p, Packages.last_hexpm_snapshot(p).data}
          end),
        more?: more?
      )
    }
  end
end
