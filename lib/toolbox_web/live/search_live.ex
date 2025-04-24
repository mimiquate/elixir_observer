defmodule ToolboxWeb.SearchLive do
  use ToolboxWeb, :live_view
  alias Toolbox.Packages

  def mount(%{"term" => term}, _session, socket) do
    packages =
      Packages.search(term)
      |> Enum.map(fn package ->
        # Fix N+1 Query
        {package, Packages.last_hexpm_snapshot(package).data}
      end)

    {
      :ok,
      assign(
        socket,
        term: term,
        page_title: "\"#{term}\"",
        packages: packages
      )
    }
  end
end
