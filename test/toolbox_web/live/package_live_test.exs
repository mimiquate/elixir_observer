defmodule ToolboxWeb.PackageLiveTest do
  use ToolboxWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  use Oban.Testing, repo: Toolbox.Repo

  alias Toolbox.Packages

  describe "Package Live View" do
    setup do
      {:ok, bandit} =
        Packages.create_package(%{
          name: "bandit",
          description: "A pure Elixir HTTP server"
        })

      {:ok, _} =
        Packages.create_hexpm_snapshot(%{
          package_id: bandit.id,
          data: %{
            "meta" => %{"description" => "A pure Elixir HTTP server"},
            "downloads" => %{"recent" => 1000},
            "releases" => [
              %{
                "version" => "1.7.0",
                "url" => "https://hex.pm/api/packages/bandit/releases/1.7.0",
                "has_docs" => true,
                "inserted_at" => "2025-05-29T16:57:22.358745Z"
              },
              %{
                "version" => "1.6.11",
                "url" => "https://hex.pm/api/packages/bandit/releases/1.6.11",
                "has_docs" => true,
                "inserted_at" => "2025-03-31T15:51:08.854619Z"
              }
            ],
            "inserted_at" => "2020-11-05T17:11:46.440731Z",
            "latest_version" => "1.7.0",
            "latest_stable_version" => "1.7.0"
          }
        })

      %{package: bandit}
    end

    test "handles invalid version gracefully", %{conn: conn, package: package} do
      assert_raise ToolboxWeb.PackageLive.HexpmVersionNotFoundError, fn ->
        live(conn, ~p"/packages/#{package.name}/invalid_version")
      end
    end
  end
end
