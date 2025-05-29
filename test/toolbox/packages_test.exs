defmodule Toolbox.PackagesTest do
  use Toolbox.DataCase, async: true

  alias Toolbox.Packages
  alias Toolbox.GithubSnapshot
  alias Toolbox.HexpmSnapshot

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
      Packages.create_github_snapshot(%{
        package_id: package1.id,
        data: %{
          "stargazers_count" => 1500,
          "full_name" => "mtrudel/bandit"
        }
      })

    {:ok, _} =
      Packages.create_github_snapshot(%{
        package_id: package2.id,
        data: %{
          "stargazers_count" => 1200,
          "full_name" => "thoughtbot/bamboo"
        }
      })

    {:ok, _} =
      Packages.create_github_snapshot(%{
        package_id: package3.id,
        data: %{
          "stargazers_count" => 800,
          "full_name" => "elixir-tesla/tesla"
        }
      })

    %{packages: [package1, package2, package3]}
  end

  describe "search/1" do
    test "returns all packages for empty search term", %{packages: packages} do
      {result_packages, more?} = Packages.search("")

      # Empty string matches all packages due to ilike pattern matching
      assert length(result_packages) == length(packages)
      assert is_boolean(more?)
    end

    test "returns empty results when no packages match" do
      {packages, more?} = Packages.search("nonexistentpackage")
      assert packages == []
      assert more? == false
    end

    test "returns matching packages ordered by download count", %{packages: _packages} do
      {packages, more?} = Packages.search("ban")

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

    test "returns packages with proper associations loaded", %{packages: _packages} do
      {packages, _more?} = Packages.search("ban")

      # Should have results for "ban" search
      assert length(packages) > 0

      package = List.first(packages)
      assert %HexpmSnapshot{} = package.latest_hexpm_snapshot
      # latest_github_snapshot might be nil or loaded
      assert %GithubSnapshot{} = package.latest_github_snapshot
    end

    test "handles case-insensitive search", %{packages: _packages} do
      {packages_lower, _} = Packages.search("ban")
      {packages_upper, _} = Packages.search("BAN")
      {packages_mixed, _} = Packages.search("Ban")

      # All should return the same results (case-insensitive)
      assert length(packages_lower) == length(packages_upper)
      assert length(packages_lower) == length(packages_mixed)

      # Should find at least one package in all cases
      assert length(packages_lower) >= 1
    end

    test "partial name matching works", %{packages: _packages} do
      # Test partial matching
      {packages, _more?} = Packages.search("ba")

      # Should find packages starting with "ba" (bandit and bamboo)
      package_names = Enum.map(packages, & &1.name)

      # At least one package should match "ba"
      assert length(packages) == 2

      # All found packages should contain "ba"
      Enum.each(package_names, fn name ->
        assert String.contains?(String.downcase(name), "ba")
      end)
    end
  end
end
