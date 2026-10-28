defmodule Toolbox.Workers.CategoryWorkerTest do
  use Toolbox.DataCase, async: true
  use Oban.Testing, repo: Toolbox.Repo

  import ExUnit.CaptureLog

  alias Toolbox.Packages
  alias Toolbox.Workers.CategoryWorker

  defp create_package_with_snapshot(attrs) do
    {:ok, package} = create(:package, attrs)
    {:ok, _} = create(:hexpm_snapshot, package_id: package.id)
    package
  end

  describe "perform/1 for the cron" do
    test "enqueues one job per package without a category" do
      create_package_with_snapshot(name: "uncategorized_1")
      create_package_with_snapshot(name: "uncategorized_2")
      create_package_with_snapshot(name: "categorized", category: 92)

      assert :ok = perform_job(CategoryWorker, %{}, meta: %{"cron" => true})

      names =
        [worker: CategoryWorker]
        |> all_enqueued()
        |> Enum.map(& &1.args["name"])
        |> Enum.sort()

      assert names == ["uncategorized_1", "uncategorized_2"]
    end

    test "enqueues nothing when every package has a category" do
      create_package_with_snapshot(name: "categorized", category: 92)

      assert :ok = perform_job(CategoryWorker, %{}, meta: %{"cron" => true})
      assert [] = all_enqueued(worker: CategoryWorker)
    end
  end

  describe "perform/1 for a package" do
    test "categorizes the package" do
      test_server = Helpers.test_server_jev()
      {:ok, _} = create(:package, name: "pager")
      stub_choice(test_server, "92")

      assert :ok = perform_job(CategoryWorker, %{name: "pager", log_on_update: false})
      assert Packages.get_package_by_name("pager").category.id == 92
    end

    @tag capture_log: true
    test "returns the error so Oban retries the job" do
      test_server = Helpers.test_server_jev()
      {:ok, _} = create(:package, name: "pager")
      stub_status(test_server, 429)

      assert {:error, "Failed to classify package pager with status 429"} =
               perform_job(CategoryWorker, %{name: "pager", log_on_update: false})
    end

    test "cancels the job and logs a warning when Jev rejects the package with a 4xx" do
      test_server = Helpers.test_server_jev()
      {:ok, _} = create(:package, name: "pager")
      stub_status(test_server, 403)

      log =
        capture_log(fn ->
          assert {:cancel, "Unable to classify package pager with status 403"} =
                   perform_job(CategoryWorker, %{name: "pager", log_on_update: false})
        end)

      assert log =~ "Unable to classify package pager with status 403"
    end

    test "cancels the job and logs a warning when the package no longer exists" do
      log =
        capture_log(fn ->
          assert {:cancel, _reason} =
                   perform_job(CategoryWorker, %{name: "gone", log_on_update: false})
        end)

      assert log =~ "package gone not found"
    end
  end

  describe "recategorize/0" do
    test "enqueues one CategoryWorker job per package" do
      for n <- 1..3, do: create(:package, name: "package_#{n}")

      assert :ok = CategoryWorker.recategorize()

      names =
        [worker: CategoryWorker]
        |> all_enqueued()
        |> Enum.map(& &1.args["name"])
        |> Enum.sort()

      assert names == ["package_1", "package_2", "package_3"]
    end
  end

  describe "perform/1 for a package with log_on_update: true" do
    test "updates the category and logs the change" do
      test_server = Helpers.test_server_jev()
      {:ok, _} = create(:package, name: "moves", category: 61)
      stub_choice(test_server, "92")

      log =
        capture_log(fn ->
          assert :ok == perform_job(CategoryWorker, %{name: "moves", log_on_update: true})
        end)

      assert Packages.get_package_by_name("moves").category.id == 92
      assert log =~ "recategorized moves: ORM and Datamapping -> Pagination"
    end

    test "does not log when the category stays the same" do
      test_server = Helpers.test_server_jev()
      {:ok, _} = create(:package, name: "stays", category: 92)
      stub_choice(test_server, "92")

      log =
        capture_log(fn ->
          assert :ok == perform_job(CategoryWorker, %{name: "stays", log_on_update: true})
        end)

      refute log =~ "recategorized stays"
    end

    @tag capture_log: true
    test "returns the error so Oban retries the job" do
      test_server = Helpers.test_server_jev()
      {:ok, _} = create(:package, name: "moves", category: 61)
      stub_status(test_server, 408)

      assert {:error, "Failed to classify package moves with status 408"} =
               perform_job(CategoryWorker, %{name: "moves", log_on_update: true})

      assert Packages.get_package_by_name("moves").category.id == 61
    end
  end

  defp stub_choice(test_server, choice) do
    TestServer.add(test_server, "/v1/systemone",
      via: :post,
      to: fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{"answers" => %{"category" => %{"choice" => choice}}})
        )
      end
    )
  end

  defp stub_status(test_server, status) do
    TestServer.add(test_server, "/v1/systemone",
      via: :post,
      to: fn conn -> Plug.Conn.send_resp(conn, status, "") end
    )
  end
end
