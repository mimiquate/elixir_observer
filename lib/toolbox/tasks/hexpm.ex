defmodule Toolbox.Tasks.Hexpm do
  def run do
    Stream.unfold(1, fn
      page ->
        {
          :ok,
          {
            {_, 200, _},
            _headers,
            packages_data
          }
        } =
          Toolbox.Hexpm.get_page(page)

        Process.sleep(:timer.seconds(1))

        if packages_data == ~c"[]" do
          nil
        else
          {packages_data, page + 1}
        end
    end)
    |> Stream.each(fn packages_data ->
      packages_data
      |> Jason.decode!()
      |> Enum.each(&create_hexpm_snapshot/1)
    end)
    |> Stream.run()
  end

  def run(names) when is_list(names) do
    names |> Enum.each(&run/1)
  end

  # Useful for development to fetch only one package
  def run(name) when is_binary(name) do
    {
      :ok,
      {
        {_, 200, _},
        _headers,
        package_data
      }
    } = Toolbox.Hexpm.get_package(name)

    {
      :ok,
      {
        {_, 200, _},
        _headers,
        owners_data
      }
    } = Toolbox.Hexpm.get_package_owners(name)

    owners_data = owners_data |> Jason.decode!()

    package_data
    |> Jason.decode!()
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
