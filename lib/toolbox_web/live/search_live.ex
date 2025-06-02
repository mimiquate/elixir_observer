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
    {exact_matches, other_matches} = split_exact_matches(packages, term)

    {
      :ok,
      assign(
        socket,
        term: term,
        page_title: "\"#{term}\"",
        packages: packages,
        exact_matches: exact_matches,
        other_matches: other_matches,
        more?: more?
      )
    }
  end

  # Helper function to split exact matches from other matches
  defp split_exact_matches(packages, search_term) do
    Enum.split_with(packages, fn package ->
      String.downcase(package.name) == String.downcase(search_term)
    end)
  end
end
