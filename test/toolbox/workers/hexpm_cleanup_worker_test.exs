defmodule Toolbox.Workers.HexpmCleanupWorkerTest do
  use Toolbox.DataCase, async: true
  use Oban.Testing, repo: Toolbox.Repo

  alias Toolbox.Packages
  alias Toolbox.Workers.{HexpmCleanupWorker, HexpmWorker}

  describe "perform/1 with id and name" do
    @tag capture_log: true
    test "deletes the package when hexpm returns 404" do
      test_server = Helpers.test_server_hexpm()
      {:ok, package} = create(:package)
      {:ok, _snapshot} = create(:hexpm_snapshot, package_id: package.id)

      TestServer.add(test_server, "/packages/#{package.name}",
        to: fn conn ->
          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(404, ~s({"message": "Page not found", "status": 404}))
        end
      )

      assert perform_job(HexpmCleanupWorker, %{id: package.id, name: package.name}) == :ok

      assert Packages.get_package_by_name(package.name) == nil
    end

    @tag capture_log: true
    test "keeps the package when hexpm still returns 200" do
      test_server = Helpers.test_server_hexpm()
      {:ok, package} = create(:package)
      {:ok, _snapshot} = create(:hexpm_snapshot, package_id: package.id)

      TestServer.add(test_server, "/packages/#{package.name}",
        to: fn conn ->
          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(200, ~s({"name": "#{package.name}"}))
        end
      )

      assert perform_job(HexpmCleanupWorker, %{id: package.id, name: package.name}) == :ok

      assert %Toolbox.Package{} = Packages.get_package_by_name(package.name)
    end

    @tag capture_log: true
    test "returns an error tuple on server errors so Oban retries, and keeps the package" do
      test_server = Helpers.test_server_hexpm()
      {:ok, package} = create(:package)
      {:ok, _snapshot} = create(:hexpm_snapshot, package_id: package.id)

      TestServer.add(test_server, "/packages/#{package.name}",
        to: fn conn ->
          Plug.Conn.send_resp(conn, 502, "")
        end
      )

      assert {:error, message} =
               perform_job(HexpmCleanupWorker, %{id: package.id, name: package.name})

      assert message =~ "502"
      assert %Toolbox.Package{} = Packages.get_package_by_name(package.name)
    end
  end

  describe "perform/1 with cron" do
    test "fans out a job only for packages not synced since the last completed sync" do
      {:ok, stale_package} = create(:package)
      {:ok, stale_snapshot} = create(:hexpm_snapshot, package_id: stale_package.id)

      one_hour_ago =
        DateTime.utc_now() |> DateTime.add(-1, :hour) |> DateTime.truncate(:second)

      from(hs in Toolbox.HexpmSnapshot, where: hs.id == ^stale_snapshot.id)
      |> Repo.update_all(set: [inserted_at: one_hour_ago])

      HexpmWorker.new(%{},
        meta: %{cron: true},
        state: "completed",
        inserted_at: DateTime.utc_now() |> DateTime.add(-30, :minute)
      )
      |> Repo.insert!()

      {:ok, fresh_package} = create(:package)
      {:ok, _fresh_snapshot} = create(:hexpm_snapshot, package_id: fresh_package.id)

      assert perform_job(HexpmCleanupWorker, %{}, meta: %{"cron" => true}) == :ok

      assert_enqueued(
        worker: HexpmCleanupWorker,
        args: %{id: stale_package.id, name: stale_package.name}
      )

      refute_enqueued(
        worker: HexpmCleanupWorker,
        args: %{id: fresh_package.id, name: fresh_package.name}
      )
    end

    test "skips the cleanup when there is no completed sync" do
      {:ok, _package} = create(:package)

      assert perform_job(HexpmCleanupWorker, %{}, meta: %{"cron" => true}) == :ok

      refute_enqueued(worker: HexpmCleanupWorker)
    end
  end
end
