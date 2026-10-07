defmodule Toolbox.Tasks.RecategorizeTest do
  use Toolbox.DataCase, async: true
  use Oban.Testing, repo: Toolbox.Repo

  alias Toolbox.Tasks.Recategorize
  alias Toolbox.Workers.RecategorizeWorker

  describe "run/0" do
    test "enqueues one RecategorizeWorker job per package" do
      for n <- 1..3, do: create(:package, name: "package_#{n}")

      assert :ok = Recategorize.run()

      names =
        [worker: RecategorizeWorker]
        |> all_enqueued()
        |> Enum.map(& &1.args["name"])
        |> Enum.sort()

      assert names == ["package_1", "package_2", "package_3"]
    end
  end
end
