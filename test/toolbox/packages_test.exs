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
  end

  describe "bulk_update_community_resources/1" do
    setup do
      {:ok, p} = Packages.create_package(%{name: "test"})

      %{package: p}
    end

    test "updates packages resources", %{package: package} do
      attrs = %{
        package.name => [
          %{
            "type" => "video",
            "title" => "Resource 1",
            "description" => "Description 1",
            "url" => "Url 1"
          }
        ]
      }

      assert {:ok, _} = Packages.bulk_update_community_resources(attrs)

      package = Repo.reload!(package)

      assert package.community_resources == [
               %Toolbox.Package.CommunityResource{
                 type: :video,
                 title: "Resource 1",
                 description: "Description 1",
                 url: "Url 1"
               }
             ]
    end
  end
end
