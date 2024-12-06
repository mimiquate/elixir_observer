defmodule ToolboxWeb.PackageController do
  use ToolboxWeb, :controller

  def show(conn, %{"name" => name}) do
    render(conn, :show, package: package(name), page_title: name)
  end

  defp package(name) do
    packages()
    |> Enum.find(fn package ->
      package["name"] == name
    end)
  end

  defp packages do
    File.read!("packages_data/packages-001.json")
    |> Jason.decode!()
  end
end
