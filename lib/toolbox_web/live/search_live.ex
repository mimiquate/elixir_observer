defmodule ToolboxWeb.SearchLive do
  use ToolboxWeb, :live_view
  alias Toolbox.Packages

  def mount(%{"term" => term}, _session, socket) do
    {packages, more?} = Packages.search(term)

    hexpm_snapshots =
      Packages.last_hexpm_snapshot(packages)
      |> Enum.into(%{}, fn h -> {h.package_id, h.data} end)

    {
      :ok,
      assign(
        socket,
        term: term,
        page_title: "\"#{term}\"",
        packages: packages,
        hexpm_snapshots: hexpm_snapshots,
        more?: more?
      )
    }
  end
end
