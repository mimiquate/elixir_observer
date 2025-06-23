defmodule Toolbox.HexpmSnapshot do
  use Ecto.Schema
  import Ecto.Changeset

  schema "hexpm_snapshots" do
    field :data, :map

    belongs_to :package, Toolbox.Package

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(hexpm_snapshot, attrs) do
    hexpm_snapshot
    |> cast(attrs, [:data, :package_id])
    |> validate_required([:data, :package_id])
    |> normalize_recent_downloads()
  end

  defp normalize_recent_downloads(changeset) do
    case get_change(changeset, :data) do
      %{"downloads" => d} = data when d == %{} ->
        put_change(
          changeset,
          :data,
          Map.put(data, "downloads", %{
            "recent" => 0
          })
        )

      _ ->
        changeset
    end
  end
end
