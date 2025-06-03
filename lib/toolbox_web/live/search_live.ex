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

    {exact_match, other_results, more?} = Packages.search(term)

    {
      :ok,
      assign(
        socket,
        term: term,
        page_title: "\"#{term}\"",
        exact_match: exact_match,
        other_results: other_results,
        results_count: length(if(exact_match, do: [exact_match], else: []) ++ other_results),
        more?: more?
      )
    }
  end
end
