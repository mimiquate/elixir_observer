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
      |> Enum.each(fn package_data ->
        package_data
        |> put_owners()
        |> create_hexpm_snapshot()
      end)
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

    package_data
    |> Jason.decode!()
    |> put_owners()
    |> create_hexpm_snapshot()
  end

  defp put_owners(package_data) do
    {
      :ok,
      {
        {_, 200, _},
        _headers,
        owners_data
      }
    } = Toolbox.Hexpm.get_package_owners(package_data["name"])

    owners_data = owners_data |> Jason.decode!()

    package_data
    |> Map.put("owners", owners_data)
  end

  defp create_hexpm_snapshot(package_data) do
    name = package_data["name"]

    package =
      case Toolbox.Packages.get_package_by_name(name) do
        %Toolbox.Package{} = p ->
          p

        _ ->
          {:ok, p} = Toolbox.Packages.create_package(%{name: name})
          p
      end

    {:ok, _hexpm_snaphost} =
      Toolbox.Packages.create_hexpm_snapshot(%{package_id: package.id, data: package_data})
  end
end
