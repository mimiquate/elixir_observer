defmodule ToolboxWeb.Admin.PackageLive do
  use ToolboxWeb, :live_view

  def mount(%{"name" => name}, _session, socket) do
    package = Toolbox.Packages.get_package_by_name(name)

    {
      :ok,
      assign(socket, package: package)
    }
  end
end
