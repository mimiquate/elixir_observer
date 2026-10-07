defmodule Toolbox.Workers.RecategorizeWorkerTest do
  use Toolbox.DataCase, async: true
  use Oban.Testing, repo: Toolbox.Repo

  import ExUnit.CaptureLog

  alias Toolbox.Packages
  alias Toolbox.Workers.RecategorizeWorker

  describe "perform/1" do
    test "updates the category and logs the change" do
      test_server = Helpers.test_server_jev()
      {:ok, _} = create(:package, name: "moves", category: 61)
      stub_choice(test_server, "92")

      log =
        capture_log(fn ->
          assert :ok == perform_job(RecategorizeWorker, %{name: "moves"})
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
          assert :ok == perform_job(RecategorizeWorker, %{name: "stays"})
        end)

      refute log =~ "recategorized stays"
    end

    test "logs 'none' as the previous category for an uncategorized package" do
      test_server = Helpers.test_server_jev()
      {:ok, _} = create(:package, name: "fresh")
      stub_choice(test_server, "92")

      log = capture_log(fn -> perform_job(RecategorizeWorker, %{name: "fresh"}) end)

      assert log =~ "recategorized fresh: none -> Pagination"
    end

    @tag capture_log: true
    test "returns the error so Oban retries the job" do
      test_server = Helpers.test_server_jev()
      {:ok, _} = create(:package, name: "moves", category: 61)
      # Req makes 1 request + 2 retries before returning the error to the worker
      for _ <- 1..3, do: stub_status(test_server, 502)

      assert {:error, {:http_status, 502}} = perform_job(RecategorizeWorker, %{name: "moves"})
      assert Packages.get_package_by_name("moves").category.id == 61
    end

    test "cancels the job and logs a warning when the package no longer exists" do
      log =
        capture_log(fn ->
          assert {:cancel, _reason} = perform_job(RecategorizeWorker, %{name: "gone"})
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
