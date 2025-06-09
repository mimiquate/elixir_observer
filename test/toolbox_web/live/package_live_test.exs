defmodule ToolboxWeb.PackageLiveTest do
  use ToolboxWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  use Oban.Testing, repo: Toolbox.Repo

  alias Toolbox.Packages

  describe "Package Live View" do
    setup do
      {:ok, bandit} =
        Packages.create_package(%{
          name: "bandit_#{System.unique_integer([:positive])}",
          description: "A pure Elixir HTTP server"
        })

      {:ok, _} =
        Packages.create_hexpm_snapshot(%{
          package_id: bandit.id,
          data: %{
            "meta" => %{"description" => "A pure Elixir HTTP server"},
            "downloads" => %{"recent" => 1000},
            "releases" => [
              %{
                "version" => "1.7.0",
                "url" => "https://hex.pm/api/packages/bandit/releases/1.7.0",
                "has_docs" => true,
                "inserted_at" => "2025-05-29T16:57:22.358745Z"
              },
              %{
                "version" => "1.6.11",
                "url" => "https://hex.pm/api/packages/bandit/releases/1.6.11",
                "has_docs" => true,
                "inserted_at" => "2025-03-31T15:51:08.854619Z"
              }
            ],
            "inserted_at" => "2020-11-05T17:11:46.440731Z",
            "latest_version" => "1.7.0",
            "latest_stable_version" => "1.7.0"
          }
        })

      %{package: bandit}
    end

    test "mounts successfully", %{conn: conn, package: package} do
      Packages.update_package_owners(package, %{
        hexpm_owners_sync_at: DateTime.utc_now,
        hexpm_owners: [%{email: "test@example.com", username: "owner"}]
      })

      Packages.update_package_latest_stable_version(package, %{
        hexpm_latest_stable_version_data: %{
          published_at: DateTime.utc_now,
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
  end
end
