defmodule Toolbox.PackagesTest do
  use Toolbox.DataCase, async: true

  alias Toolbox.Packages
  alias Toolbox.Package

  describe "search/1" do
    setup do
      # Create test data for search functionality
      {:ok, package1} = Packages.create_package(%{name: "bandit"})
      {:ok, package2} = Packages.create_package(%{name: "bamboo"})
      {:ok, package3} = Packages.create_package(%{name: "tesla"})

      # Create hexpm snapshots with test data
      {:ok, _} =
        Packages.create_hexpm_snapshot(%{
          package_id: package1.id,
          data: %{
            "meta" => %{"description" => "A pure Elixir HTTP server"},
            "downloads" => %{"recent" => 1000}
          }
        })

      {:ok, _} =
        Packages.create_hexpm_snapshot(%{
          package_id: package2.id,
          data: %{
            "meta" => %{"description" => "Composable, testable & adapter based emails"},
            "downloads" => %{"recent" => 800}
          }
        })

      {:ok, _} =
        Packages.create_hexpm_snapshot(%{
          package_id: package3.id,
          data: %{
            "meta" => %{"description" => "HTTP client library"},
            "downloads" => %{"recent" => 500}
          }
        })

      # Create github snapshots with test data
      {:ok, _} =
        Packages.upsert_github_snapshot(%{
          package_id: package1.id,
          data: %{
            "stargazers_count" => 1500,
            "full_name" => "mtrudel/bandit"
          }
        })

      {:ok, _} =
        Packages.upsert_github_snapshot(%{
          package_id: package2.id,
          data: %{
            "stargazers_count" => 1200,
            "full_name" => "thoughtbot/bamboo"
          }
        })

      {:ok, _} =
        Packages.upsert_github_snapshot(%{
          package_id: package3.id,
          data: %{
            "stargazers_count" => 800,
            "full_name" => "elixir-tesla/tesla"
          }
        })

      %{packages: [package1, package2, package3]}
    end

    test "returns all packages for empty search term", %{packages: packages} do
      {result_packages, more?} =
        "" |> Toolbox.PackageSearch.parse() |> Toolbox.PackageSearch.execute()

      # Empty string matches all packages due to ilike pattern matching in keyword_search
      # When using execute/1 directly, it bypasses the executable? check
      assert length(result_packages) == length(packages)
      assert is_boolean(more?)
    end

    test "returns empty results when no packages match" do
      {packages, more?} =
        "nonexistentpackage" |> Toolbox.PackageSearch.parse() |> Toolbox.PackageSearch.execute()

      assert packages == []
      assert more? == false
    end

    test "returns matching packages ordered by download count", %{packages: _packages} do
      {packages, more?} =
        "ban" |> Toolbox.PackageSearch.parse() |> Toolbox.PackageSearch.execute()

      # Should find packages that match "ban" (bandit, bamboo)
      # At least one package should match
      assert length(packages) >= 1
      assert is_boolean(more?)

      # Check that results contain expected packages
      package_names = Enum.map(packages, & &1.name)

      # At least one of bandit or bamboo should be found
      assert "bandit" in package_names || "bamboo" in package_names

      # If we have multiple results, they should be ordered by download count (descending)
      downloads =
        Enum.map(packages, fn pkg ->
          pkg.latest_hexpm_snapshot.data["downloads"]["recent"]
        end)

      assert downloads == Enum.sort(downloads, :desc)
    end

    test "handles case-insensitive search", %{packages: [bandit | _]} do
      {[%Package{name: name}], _more?} =
        "Ban" |> Toolbox.PackageSearch.parse() |> Toolbox.PackageSearch.execute()

      assert name == bandit.name
    end

    test "properly handles packages with nil downloads in sorting" do
      # Create a package with nil downloads
      {:ok, nil_downloads_package} = Packages.create_package(%{name: "nil_downloads_pkg"})

      {:ok, _} =
        Packages.create_hexpm_snapshot(%{
          package_id: nil_downloads_package.id,
          data: %{
            "meta" => %{"description" => "Package with nil downloads"},
            "downloads" => %{}
          }
        })

      # Create a package with high downloads
      {:ok, high_downloads_package} = Packages.create_package(%{name: "high_downloads_pkg"})

      {:ok, _} =
        Packages.create_hexpm_snapshot(%{
          package_id: high_downloads_package.id,
          data: %{
            "meta" => %{"description" => "Package with high downloads"},
            "downloads" => %{"recent" => 2000}
          }
        })

      # Search for packages containing "pkg"
      {packages, _more?} =
        "pkg" |> Toolbox.PackageSearch.parse() |> Toolbox.PackageSearch.execute()

      # Check actual ordering - nil downloads should come AFTER packages with downloads
      assert [%{name: "high_downloads_pkg"}, %{name: "nil_downloads_pkg"}] = packages
    end
  end

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
end
