defmodule Toolbox.Workers.HexpmWorkerTest do
  use Toolbox.DataCase, async: true
  use Oban.Testing, repo: Toolbox.Repo

  import ExUnit.CaptureLog

  alias Toolbox.Packages
  alias Toolbox.Workers.HexpmWorker

  describe "perform/1 with get_latest_stable_version" do
    test "updates the package and broadcasts on success" do
      test_server = Helpers.test_server_hexpm()
      {:ok, package} = create(:package)

      Phoenix.PubSub.subscribe(Toolbox.PubSub, "package_live:#{package.name}")

      TestServer.add(test_server, "/packages/#{package.name}/releases/1.7.0",
        to: fn conn ->
          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(200, ~s({
            "version": "1.7.0",
            "meta": {"elixir": "~> 1.14"},
            "has_docs": true,
            "retirement": null,
            "requirements": {},
            "inserted_at": "2026-08-25T09:12:05Z",
            "publisher": {"username": "someuser", "email": "user@example.com"}
          }))
        end
      )

      assert {:ok, %Toolbox.Package{} = updated} =
               perform_job(HexpmWorker, %{
                 action: "get_latest_stable_version",
                 name: package.name,
                 version: "1.7.0"
               })

      assert updated.hexpm_latest_stable_version_data.version == "1.7.0"

      assert_receive %{
        action: :refresh_latest_stable_version,
        latest_stable_version_data: %{version: "1.7.0"}
      }
    end

    @tag capture_log: true
    test "returns :ok and skips the update on 404 (nonexistent release)" do
      test_server = Helpers.test_server_hexpm()
      {:ok, package} = create(:package)

      TestServer.add(test_server, "/packages/#{package.name}/releases/1.0.0",
        to: fn conn ->
          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(404, ~s({"message": "Page not found", "status": 404}))
        end
      )

      assert perform_job(HexpmWorker, %{
               action: "get_latest_stable_version",
               name: package.name,
               version: "1.0.0"
             }) == :ok

      assert Packages.get_package_by_name(package.name).hexpm_latest_stable_version_data == nil
    end

    test "returns :ok and never calls hex.pm when version is nil" do
      Helpers.test_server_hexpm()
      {:ok, package} = create(:package)

      log =
        capture_log(fn ->
          assert perform_job(HexpmWorker, %{
                   action: "get_latest_stable_version",
                   name: package.name,
                   version: nil
                 }) == :ok
        end)

      assert log =~ "has no latest stable version, skipping version fetch"
      assert Packages.get_package_by_name(package.name).hexpm_latest_stable_version_data == nil
    end

    @tag capture_log: true
    test "returns an error tuple on server errors so Oban retries" do
      test_server = Helpers.test_server_hexpm()
      {:ok, package} = create(:package)

      TestServer.add(test_server, "/packages/#{package.name}/releases/1.7.0",
        to: fn conn ->
          Plug.Conn.send_resp(conn, 502, "")
        end
      )

      assert {:error, message} =
               perform_job(HexpmWorker, %{
                 action: "get_latest_stable_version",
                 name: package.name,
                 version: "1.7.0"
               })

      assert message =~ "502"
    end
  end
end
