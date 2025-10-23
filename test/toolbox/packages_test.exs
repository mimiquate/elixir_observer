defmodule Toolbox.PackagesTest do
  use Toolbox.DataCase, async: true

  describe "create_hexpm_snapshot/1" do
    test "add default if missing downloads" do
      {:ok, snapshot} =
        create(:hexpm_snapshot, data: %{"downloads" => %{}})

      assert snapshot.data["downloads"] == %{"recent" => 0}
    end

    test "does not modify downloads if present" do
      {:ok, snapshot} =
        create(:hexpm_snapshot,
          data: %{"downloads" => %{"all" => 10, "recent" => 5}}
        )

      assert snapshot.data["downloads"] == %{"all" => 10, "recent" => 5}
    end
  end
end
