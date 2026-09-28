defmodule Toolbox.Workers.SCMWorkerTest do
  use Toolbox.DataCase, async: true
  use Oban.Testing, repo: Toolbox.Repo

  import ExUnit.CaptureLog

  alias Toolbox.Workers.SCMWorker

  describe "perform/1 with name" do
    test "returns :ok and skips the run when the package no longer exists" do
      log =
        capture_log(fn ->
          assert :ok == perform_job(SCMWorker, %{name: "does_not_exist"})
        end)

      assert log =~ "package does_not_exist not found"
    end
  end
end
