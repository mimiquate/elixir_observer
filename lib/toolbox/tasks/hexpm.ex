defmodule Toolbox.Tasks.Hexpm do
  def run do
    Stream.unfold(1, fn
      page ->
        {:ok, %{status: 200, body: packages_data}} = Toolbox.Hexpm.get_page(page)

        Process.sleep(:timer.seconds(1))

        if packages_data == [] do
          nil
        else
          {packages_data, page + 1}
        end
    end)
    |> Stream.each(fn packages_data ->
      packages_data
      |> Enum.each(fn p ->
        Toolbox.Repo.transact(fn ->
          Toolbox.Packages.skip_refresh_latest_hexpm_snapshots()
          create_hexpm_snapshot(p)
        end)
      end)
    end)
    |> Stream.run()

    Toolbox.Packages.refresh_latest_hexpm_snapshots()
  end

  def run(names) when is_list(names) do
    names |> Enum.each(&run/1)
  end

  # Useful for development to fetch only one package
  def run(name) when is_binary(name) do
    {:ok, %{status: 200, body: package_data}} = Toolbox.Hexpm.get_package(name)
    {:ok, %{status: 200, body: owners_data}} = Toolbox.Hexpm.get_package_owners(name)

    package_data
    |> Map.put("owners", owners_data)
    |> create_hexpm_snapshot()
  end

  defp create_hexpm_snapshot(package_data) do
    name = package_data["name"]
    description = package_data["meta"]["description"]

    package =
      case Toolbox.Packages.get_package_by_name(name) do
        %Toolbox.Package{} = p ->
          p

        _ ->
          {:ok, p} = Toolbox.Packages.create_package(%{name: name, description: description})
          p
      end

    {:ok, _hexpm_snaphost} =
      Toolbox.Packages.create_hexpm_snapshot(%{package_id: package.id, data: package_data})
  end
end
