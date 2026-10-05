defmodule Toolbox.Tasks.RecategorizeTest do
  use Toolbox.DataCase, async: true
  use Oban.Testing, repo: Toolbox.Repo

  alias Toolbox.Tasks.Recategorize
  alias Toolbox.Workers.RecategorizeWorker

  defp create_packages(count) do
    for n <- 1..count do
      {:ok, _package} = create(:package, name: "package_#{n}")
    end
  end

  describe "run/0" do
    test "enqueues a RecategorizeWorker job with every package name" do
      create_packages(2)

      Recategorize.run()

      assert [%{args: %{"names" => names}}] = all_enqueued(worker: RecategorizeWorker)

      assert Enum.sort(names) == ["package_1", "package_2"]
    end

    test "splits the package names in chunks of 300" do
      create_packages(301)

      Recategorize.run()

      sizes =
        [worker: RecategorizeWorker]
        |> all_enqueued()
        |> Enum.map(&length(&1.args["names"]))
        |> Enum.sort()

      assert sizes == [1, 300]
    end
  end
end
