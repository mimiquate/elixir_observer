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
  end
end
