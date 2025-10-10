defmodule ToolboxWeb.Admin.PackageLive do
  use ToolboxWeb, :live_view

  def mount(%{"name" => name}, _session, socket) do
    package = Toolbox.Packages.get_package_by_name!(name)

    {
      :ok,
      assign(socket,
        search_term: "",
        package: package,
        page_title: "#{name} - Admin"
      )
    }
  end
end
