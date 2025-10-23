defmodule ToolboxWeb.PackageLiveTest do
  use ToolboxWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  use Oban.Testing, repo: Toolbox.Repo

  alias Toolbox.Packages

  describe "Package Live View" do
    setup context do
      params =
        if Map.get(context, :package_name) do
          [name: Map.get(context, :package_name)]
        else
          []
        end

      {:ok, package} = create(:package, params)
      {:ok, _} = create(:hexpm_snapshot, package_id: package.id)

      [package: package]
    end

    test "mounts successfully", %{conn: conn, package: package} do
      Packages.update_package_owners(package, %{
        hexpm_owners_sync_at: DateTime.utc_now(),
        hexpm_owners: [%{email: "test@example.com", username: "owner"}]
      })

      Packages.update_package_latest_stable_version(package, %{
        hexpm_latest_stable_version_data: %{
          published_at: DateTime.utc_now(),
          published_by_username: "username",
          version: "1.7.0"
        }
      })

      {:ok, view, _html} = live(conn, ~p"/packages/#{package.name}")

      assert page_title(view) =~ package.name
      assert has_element?(view, "[data-test-package-name]", package.name)
      assert has_element?(view, "[data-test-package-description]", package.description)

      assert all_enqueued(worker: Toolbox.Workers.HexpmWorker) == []
    end

    test "mounts successfully when missing external data", %{conn: conn, package: package} do
      {:ok, view, _html} = live(conn, ~p"/packages/#{package.name}")

      assert page_title(view) =~ package.name
      assert has_element?(view, "[data-test-package-name]", package.name)
      assert has_element?(view, "[data-test-package-description]", package.description)

      [version_job, owner_job] = all_enqueued(worker: Toolbox.Workers.HexpmWorker)

      assert version_job.args == %{
               "action" => "get_latest_stable_version",
               "name" => package.name,
               "version" => "1.7.0"
             }

      assert owner_job.args == %{
               "action" => "get_package_owners",
               "name" => package.name
             }
    end

    test "handles invalid version gracefully", %{conn: conn, package: package} do
      assert_raise ToolboxWeb.PackageLive.HexpmVersionNotFoundError, fn ->
        live(conn, ~p"/packages/#{package.name}/invalid_version")
      end
    end

    test "displays package owners section when owners exist", %{conn: conn, package: package} do
      owners = [
        %{email: "jose.valim@example.com", username: "josevalim"},
        %{email: "chris.mccord@example.com", username: "chrismccord"},
        %{email: "andrea.leopardi@example.com", username: "whatyouhide"}
      ]

      Packages.update_package_owners(package, %{
        hexpm_owners_sync_at: DateTime.utc_now(),
        hexpm_owners: owners
      })

      {:ok, view, _html} = live(conn, ~p"/packages/#{package.name}")

      assert has_element?(view, "[data-test-package-owners-section]")
      assert has_element?(view, "[data-test-owner-chip='josevalim']")
      assert has_element?(view, "[data-test-owner-chip='chrismccord']")
      assert has_element?(view, "[data-test-owner-chip='whatyouhide']")
    end

    test "displays first 4 owners as chips", %{conn: conn, package: package} do
      owners = [
        %{email: "jose.valim@example.com", username: "josevalim"},
        %{email: "chris.mccord@example.com", username: "chrismccord"},
        %{email: "andrea.leopardi@example.com", username: "whatyouhide"},
        %{email: "michał.muskała@example.com", username: "michalmuskala"}
      ]

      Packages.update_package_owners(package, %{
        hexpm_owners_sync_at: DateTime.utc_now(),
        hexpm_owners: owners
      })

      {:ok, view, _html} = live(conn, ~p"/packages/#{package.name}")

      assert has_element?(view, "[data-test-owner-chip='josevalim']")
      assert has_element?(view, "[data-test-owner-chip='chrismccord']")
      assert has_element?(view, "[data-test-owner-chip='whatyouhide']")
      assert has_element?(view, "[data-test-owner-chip='michalmuskala']")
      refute has_element?(view, "[data-test-owners-show-more-button]")
    end

    test "shows 'show more' button when more than 4 owners exist", %{conn: conn, package: package} do
      owners = [
        %{email: "jose.valim@example.com", username: "josevalim"},
        %{email: "chris.mccord@example.com", username: "chrismccord"},
        %{email: "andrea.leopardi@example.com", username: "whatyouhide"},
        %{email: "michał.muskała@example.com", username: "michalmuskala"},
        %{email: "wojtek.mach@example.com", username: "wojtekmach"},
        %{email: "devon.estes@example.com", username: "devonestes"}
      ]

      Packages.update_package_owners(package, %{
        hexpm_owners_sync_at: DateTime.utc_now(),
        hexpm_owners: owners
      })

      {:ok, view, _html} = live(conn, ~p"/packages/#{package.name}")

      assert has_element?(view, "[data-test-owner-chip='josevalim']")
      assert has_element?(view, "[data-test-owner-chip='chrismccord']")
      assert has_element?(view, "[data-test-owner-chip='whatyouhide']")
      assert has_element?(view, "[data-test-owner-chip='michalmuskala']")
      refute has_element?(view, "[data-test-owner-chip='wojtekmach']")
      refute has_element?(view, "[data-test-owner-chip='devonestes']")
      assert has_element?(view, "[data-test-owners-show-more-button]")
      assert element(view, "[data-test-owners-show-more-button]") |> render() =~ "+ 2 owners"
    end

    test "toggles owners popover when clicking show more button", %{conn: conn, package: package} do
      owners = [
        %{email: "jose.valim@example.com", username: "josevalim"},
        %{email: "chris.mccord@example.com", username: "chrismccord"},
        %{email: "andrea.leopardi@example.com", username: "whatyouhide"},
        %{email: "michał.muskała@example.com", username: "michalmuskala"},
        %{email: "wojtek.mach@example.com", username: "wojtekmach"},
        %{email: "devon.estes@example.com", username: "devonestes"}
      ]

      Packages.update_package_owners(package, %{
        hexpm_owners_sync_at: DateTime.utc_now(),
        hexpm_owners: owners
      })

      {:ok, view, _html} = live(conn, ~p"/packages/#{package.name}")

      # Initially popover should not be visible
      refute has_element?(view, "[data-test-owners-popover]")

      # Click the show more button
      view
      |> element("[data-test-owners-show-more-button]")
      |> render_click()

      # Popover should now be visible with additional owners
      assert has_element?(view, "[data-test-owners-popover]")
      assert has_element?(view, "[data-test-owners-popover-content]")

      # Additional owners should be visible in popover
      assert has_element?(view, "[data-test-owners-popover] [data-test-owner-chip='wojtekmach']")
      assert has_element?(view, "[data-test-owners-popover] [data-test-owner-chip='devonestes']")
    end

    test "hides owners popover when clicking show more button again", %{
      conn: conn,
      package: package
    } do
      owners = [
        %{email: "jose.valim@example.com", username: "josevalim"},
        %{email: "chris.mccord@example.com", username: "chrismccord"},
        %{email: "andrea.leopardi@example.com", username: "whatyouhide"},
        %{email: "michał.muskała@example.com", username: "michalmuskala"},
        %{email: "wojtek.mach@example.com", username: "wojtekmach"}
      ]

      Packages.update_package_owners(package, %{
        hexpm_owners_sync_at: DateTime.utc_now(),
        hexpm_owners: owners
      })

      {:ok, view, _html} = live(conn, ~p"/packages/#{package.name}")

      # Show popover
      view
      |> element("[data-test-owners-show-more-button]")
      |> render_click()

      assert has_element?(view, "[data-test-owners-popover]")

      # Click again to hide popover
      view
      |> element("[data-test-owners-show-more-button]")
      |> render_click()

      refute has_element?(view, "[data-test-owners-popover]")
    end

    test "package owners section works with empty owners list", %{conn: conn, package: package} do
      Packages.update_package_owners(package, %{
        hexpm_owners_sync_at: DateTime.utc_now(),
        hexpm_owners: []
      })

      {:ok, view, _html} = live(conn, ~p"/packages/#{package.name}")

      assert has_element?(view, "[data-test-package-owners-section]")
      refute has_element?(view, "[data-test-owner-chip]")
      refute has_element?(view, "[data-test-owners-show-more-button]")
    end

    @tag package_name: "test"
    test "displays community section when package has resources", %{conn: conn, package: package} do
      {:ok, view, _html} = live(conn, ~p"/packages/#{package.name}")

      assert has_element?(view, data_test_attr(:community_section))
      refute has_element?(view, data_test_attr(:community_section_empty))
    end

    test "does not display community section when package doesn't have resources", %{
      conn: conn,
      package: package
    } do
      {:ok, view, _html} = live(conn, ~p"/packages/#{package.name}")

      assert has_element?(view, data_test_attr(:community_section))
      assert has_element?(view, data_test_attr(:community_section_empty))
    end
  end
end
