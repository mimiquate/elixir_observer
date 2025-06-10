defmodule Toolbox.Tasks.SCMTest do
  use Toolbox.DataCase, async: true

  alias Toolbox.Packages
  alias Toolbox.Tasks.SCM

  describe "run/1" do
    test "add GitHub info", %{} do
      {:ok, package} = Packages.create_package(%{name: "test_package"})

      Packages.create_hexpm_snapshot(%{
        package_id: package.id,
        data: %{
          "meta" => %{
            "links" => %{
              "GitHub" => "https://github.com/owner/test_package"
            }
          }
        }
      })

      TestServer.add("/repos/owner/test_package",
        to: fn conn ->
          Plug.Conn.send_resp(conn, 200, ~s({"id": 123}))
        end
      )

      TestServer.add("/graphql",
        via: :post,
        to: fn conn ->
          Plug.Conn.send_resp(conn, 200, ~s({"open_pr": 10}))
        end
      )

      Application.put_env(:toolbox, :github_base_url, TestServer.url())

      SCM.run([package.name])

      snapshot = Packages.get_package_by_name(package.name).latest_github_snapshot

      assert snapshot.data == %{
               "activity" => %{"open_pr" => 10},
               "id" => 123,
               "has_changelog" => false
             }
    end

    test "delete old snapshot when not found GitHub", %{} do
      {:ok, package} = Packages.create_package(%{name: "test_package"})

      Packages.create_hexpm_snapshot(%{
        package_id: package.id,
        data: %{
          "meta" => %{
            "links" => %{
              "GitHub" => "https://github.com/owner/non_existent_repo"
            }
          }
        }
      })

      Packages.upsert_github_snapshot(%{
        package_id: package.id,
        data: %{}
      })

      TestServer.add("/repos/owner/non_existent_repo",
        to: fn conn ->
          Plug.Conn.send_resp(conn, 404, "")
        end
      )

      Application.put_env(:toolbox, :github_base_url, TestServer.url())

      SCM.run([package.name])

      refute Packages.get_package_by_name(package.name).latest_github_snapshot
    end
  end
end
