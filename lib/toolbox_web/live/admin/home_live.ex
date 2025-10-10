defmodule ToolboxWeb.Admin.HomeLive do
  use ToolboxWeb, :live_view

  def mount(_params, _session, socket) do
    {
      :ok,
      assign(
        socket,
        search_term: "",
        page_title: "Admin",
        packages_total_count: Toolbox.Packages.total_count(),
        packages: Toolbox.Packages.list_packages()
      )
    }
  end
end
