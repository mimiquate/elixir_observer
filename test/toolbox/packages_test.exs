defmodule Toolbox.PackagesTest do
  use Toolbox.DataCase, async: true

  alias Toolbox.Packages

  describe "create_hexpm_snapshot/1" do
    setup do
      {:ok, p} = Packages.create_package(%{name: "test"})
      %{package: p}
    end

    test "add default if missing downloads", %{package: package} do
      {:ok, snapshot} =
        Packages.create_hexpm_snapshot(%{
          package_id: package.id,
          data: %{"downloads" => %{}}
        })

         package
         |> Ecto.Changeset.cast(%{name: "bandit"}, [:name])
         |> Toolbox.Repo.update!(returning: true)

      assert snapshot.data["downloads"] == %{"recent" => 0}
    end
  end
end
