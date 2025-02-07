defmodule Toolbox.GithubSnapshot do
  use Ecto.Schema
  import Ecto.Changeset

  schema "github_snapshots" do
    field :data, :map

    belongs_to :package, Toolbox.Package

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(github_snapshot, attrs) do
    github_snapshot
    |> cast(attrs, [:data, :package_id])
    |> validate_required([:data, :package_id])
  end
end
