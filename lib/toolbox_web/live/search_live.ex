defmodule ToolboxWeb.SearchLive do
  use ToolboxWeb, :live_view
  alias Toolbox.Packages

  import ToolboxWeb.Components.Icons.StarIcon
  import ToolboxWeb.Components.Icons.DownloadIcon

  def mount(%{"term" => term}, _session, socket) do
    Logger.metadata(
      tower: %{
        search_term: term,
        user_agent: get_connect_info(socket, :user_agent)
      }
    )

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
