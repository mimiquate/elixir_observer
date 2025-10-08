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

      assert snapshot.data["downloads"] == %{"recent" => 0}
    end

    test "does not modify downloads if present", %{package: package} do
      {:ok, snapshot} =
        Packages.create_hexpm_snapshot(%{
          package_id: package.id,
          data: %{"downloads" => %{"all" => 10, "recent" => 5}}
        })

      assert snapshot.data["downloads"] == %{"all" => 10, "recent" => 5}
    end

    test "return packages by name", %{package: package} do
      assert [package] ==
               Packages.list_packages_by_names(["test"], :as_query) |> Toolbox.Repo.all()

      assert [] ==
               Packages.list_packages_by_names(["fake_package"], :as_query) |> Toolbox.Repo.all()
    end
  end
end
