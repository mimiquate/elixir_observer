defmodule Toolbox.Factory do
  alias Toolbox.Packages

  def create(model, params \\ [])

  def create(:package, params) do
    defaults = %{
      name: "bandit_#{System.unique_integer([:positive])}",
      description: "A pure Elixir HTTP server"
    }

    defaults
    |> Map.merge(Enum.into(params, %{}))
    |> Packages.create_package()
  end

  def create(:hexpm_snapshot, params) do
    {package_id, params} =
      Keyword.pop_lazy(params, :package_id, fn ->
        {:ok, package} = create(:package)

        package.id
      end)

    defaults = %{
      package_id: package_id,
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
    }

    defaults
    |> Map.merge(Enum.into(params, %{}))
    |> Packages.create_hexpm_snapshot()
  end
end
