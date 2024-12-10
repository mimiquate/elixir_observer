defmodule Toolbox.Tasks.Hexpm do
  def run do
    1..20
    |> Enum.each(fn page ->
      {
        :ok,
        {
          {_, 200, _},
          _headers,
          packages_data
        }
      } =
        Toolbox.Hexpm.get_page(page)

      packages_data
      |> Jason.decode!()
      |> Enum.each(fn package_data ->
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
      end)

      Process.sleep(:timer.seconds(1))
    end)
  end
end
