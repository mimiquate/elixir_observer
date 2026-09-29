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

  describe "perform/1 with get_package_owners" do
    test "updates the package and broadcasts on success" do
      test_server = Helpers.test_server_hexpm()
      {:ok, package} = create(:package)

      Phoenix.PubSub.subscribe(Toolbox.PubSub, "package_live:#{package.name}")

      TestServer.add(test_server, "/packages/#{package.name}/owners",
        to: fn conn ->
          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(200, ~s([
            {"email": "user@example.com", "username": "someuser"}
          ]))
        end
      )

      assert {:ok, %Toolbox.Package{} = updated} =
               perform_job(HexpmWorker, %{
                 action: "get_package_owners",
                 name: package.name
               })

      assert [%{username: "someuser", email: "user@example.com"}] = updated.hexpm_owners
      assert updated.hexpm_owners_sync_at

      assert_receive %{
        action: :refresh_owners,
        owners: [%{username: "someuser"}]
      }
    end

    @tag capture_log: true
    test "returns :ok and skips the update on 404 (package removed from hex.pm)" do
      test_server = Helpers.test_server_hexpm()
      {:ok, package} = create(:package)

      TestServer.add(test_server, "/packages/#{package.name}/owners",
        to: fn conn ->
          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(404, ~s({"message": "Page not found", "status": 404}))
        end
      )

      assert perform_job(HexpmWorker, %{
               action: "get_package_owners",
               name: package.name
             }) == :ok

      assert Packages.get_package_by_name(package.name).hexpm_owners == []
    end

    @tag capture_log: true
    test "returns an error tuple on server errors so Oban retries" do
      test_server = Helpers.test_server_hexpm()
      {:ok, package} = create(:package)

      TestServer.add(test_server, "/packages/#{package.name}/owners",
        to: fn conn ->
          Plug.Conn.send_resp(conn, 502, "")
        end
      )

      assert {:error, message} =
               perform_job(HexpmWorker, %{
                 action: "get_package_owners",
                 name: package.name
               })

      assert message =~ "502"
    end
  end

  describe "perform/1 with get_version_downloads" do
    defp releases(versions) do
      Enum.map(versions, &%{"version" => &1})
    end

    defp stub_downloads(test_server, package_name, version, downloads) do
      TestServer.add(test_server, "/packages/#{package_name}/releases/#{version}",
        to: fn conn ->
          conn = Plug.Conn.fetch_query_params(conn)

          assert conn.query_params["downloads_after"] ==
                   Date.to_iso8601(Date.add(Date.utc_today(), -90))

          assert conn.query_params["downloads_before"] ==
                   Date.to_iso8601(Date.add(Date.utc_today(), -1))

          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(200, Jason.encode!(%{"downloads" => downloads}))
        end
      )
    end

    defp create_package_with_releases(versions, recent \\ 1_000) do
      {:ok, package} = create(:package)

      {:ok, _} =
        Packages.create_hexpm_snapshot(%{
          package_id: package.id,
          data: %{
            "downloads" => %{"recent" => recent},
            "releases" => releases(versions)
          }
        })

      Packages.get_package_by_name(package.name)
    end

    test "offset 0 fetches only the first page (newest 5), leaving the rest unrequested" do
      test_server = Helpers.test_server_hexpm()

      newest_first = for n <- 8..1//-1, do: "#{n}.0.0"
      package = create_package_with_releases(newest_first)

      Phoenix.PubSub.subscribe(Toolbox.PubSub, "package_live:#{package.name}")

      for version <- ["8.0.0", "7.0.0", "6.0.0", "5.0.0", "4.0.0"] do
        stub_downloads(test_server, package.name, version, 100)
      end

      assert perform_job(HexpmWorker, %{
               action: "get_version_downloads",
               name: package.name,
               offset: 0
             }) == :ok

      assert_receive %{action: :refresh_version_downloads, offset: 0, version_downloads: entries}

      assert Enum.map(entries, & &1.version) == ["8.0.0", "7.0.0", "6.0.0", "5.0.0", "4.0.0"]
      assert Enum.all?(entries, &(&1.downloads == 100))
    end

    test "offset 5 fetches the next page (the remaining, older versions)" do
      test_server = Helpers.test_server_hexpm()

      newest_first = for n <- 8..1//-1, do: "#{n}.0.0"
      package = create_package_with_releases(newest_first)

      Phoenix.PubSub.subscribe(Toolbox.PubSub, "package_live:#{package.name}")

      for version <- ["3.0.0", "2.0.0", "1.0.0"] do
        stub_downloads(test_server, package.name, version, 50)
      end

      assert perform_job(HexpmWorker, %{
               action: "get_version_downloads",
               name: package.name,
               offset: 5
             }) == :ok

      assert_receive %{action: :refresh_version_downloads, offset: 5, version_downloads: entries}
      assert Enum.map(entries, & &1.version) == ["3.0.0", "2.0.0", "1.0.0"]
    end

    test "an offset past the end broadcasts an empty page" do
      package = create_package_with_releases(["2.0.0", "1.0.0"])

      Phoenix.PubSub.subscribe(Toolbox.PubSub, "package_live:#{package.name}")

      assert perform_job(HexpmWorker, %{
               action: "get_version_downloads",
               name: package.name,
               offset: 5
             }) == :ok

      assert_receive %{action: :refresh_version_downloads, offset: 5, version_downloads: []}
    end

    test "skips prereleases without requesting them" do
      test_server = Helpers.test_server_hexpm()

      package = create_package_with_releases(["2.0.0-rc.1", "2.0.0", "1.0.0"])

      Phoenix.PubSub.subscribe(Toolbox.PubSub, "package_live:#{package.name}")

      stub_downloads(test_server, package.name, "2.0.0", 500)
      stub_downloads(test_server, package.name, "1.0.0", 500)

      assert perform_job(HexpmWorker, %{
               action: "get_version_downloads",
               name: package.name,
               offset: 0
             }) == :ok

      assert_receive %{action: :refresh_version_downloads, version_downloads: entries}
      assert Enum.map(entries, & &1.version) == ["2.0.0", "1.0.0"]
    end

    test "returns :ok and broadcasts nothing when a version is not found on hex.pm" do
      test_server = Helpers.test_server_hexpm()

      package = create_package_with_releases(["2.0.0", "1.0.0"], 500)

      Phoenix.PubSub.subscribe(Toolbox.PubSub, "package_live:#{package.name}")

      TestServer.add(test_server, "/packages/#{package.name}/releases/2.0.0",
        to: fn conn ->
          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(404, ~s({"message": "Page not found", "status": 404}))
        end
      )

      stub_downloads(test_server, package.name, "1.0.0", 500)

      log =
        capture_log(fn ->
          assert perform_job(HexpmWorker, %{
                   action: "get_version_downloads",
                   name: package.name,
                   offset: 0
                 }) == :ok
        end)

      assert log =~ "Unable to fetch hexpm downloads for #{package.name} version 2.0.0"
      refute_receive %{action: :refresh_version_downloads}
    end

    @tag capture_log: true
    test "returns an error tuple on server errors so Oban retries" do
      test_server = Helpers.test_server_hexpm()

      package = create_package_with_releases(["1.0.0"], 500)

      TestServer.add(test_server, "/packages/#{package.name}/releases/1.0.0",
        to: fn conn -> Plug.Conn.send_resp(conn, 502, "") end
      )

      assert {:error, message} =
               perform_job(HexpmWorker, %{
                 action: "get_version_downloads",
                 name: package.name,
                 offset: 0
               })

      assert message =~ "502"
    end
  end
end
