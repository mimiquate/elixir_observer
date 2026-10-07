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

      assert :ok = perform_job(CategoryWorker, %{name: "pager"})
      assert Packages.get_package_by_name("pager").category.id == 92
    end

    @tag capture_log: true
    test "returns the error so Oban retries the job" do
      test_server = Helpers.test_server_jev()
      {:ok, _} = create(:package, name: "pager")
      # Req makes 1 request + 2 retries before returning the error to the worker
      for _ <- 1..3, do: stub_status(test_server, 529)

      assert {:error, {:http_status, 529}} = perform_job(CategoryWorker, %{name: "pager"})
    end

    test "cancels the job and logs a warning when the package no longer exists" do
      log =
        capture_log(fn ->
          assert {:cancel, _reason} = perform_job(CategoryWorker, %{name: "gone"})
        end)

      assert log =~ "package gone not found"
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
