defmodule ToolboxWeb.SearchLive do
  use ToolboxWeb, :live_view

  import ToolboxWeb.Components.Icons.StarIcon
  import ToolboxWeb.Components.Icons.DownloadIcon
  import ToolboxWeb.Components.Icons.BookmarkIcon

  def mount(%{"term" => term}, _session, socket) do
    Logger.metadata(
      tower: %{
        search_term: term,
        user_agent: get_connect_info(socket, :user_agent)
      }
    )

    %{original_term: full_term, clean_term: clean_term} =
      parsed_search = Toolbox.PackageSearch.parse(term)

    {results, more?} =
      if Toolbox.PackageSearch.executable?(parsed_search) do
        Toolbox.PackageSearch.execute(parsed_search)
      else
        {[], false}
      end

    {
      :ok,
      assign(
        socket,
        search_term: full_term,
        term: clean_term,
        page_title: "\"#{clean_term}\"",
        results: results,
        results_count: length(results),
        more?: more?
      )
    }
  end

  def handle_event("logout", _params, socket) do
    {:noreply,
     socket
     |> redirect(to: ~p"/auth/logout")}
  end
end
