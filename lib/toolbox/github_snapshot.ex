defmodule Toolbox.GithubSnapshot do
  use Ecto.Schema
  import Ecto.Changeset

  schema "github_snapshots" do
    field :data, :map
    embeds_one :activity, Toolbox.GithubSnapshot.Activity, on_replace: :delete

    belongs_to :package, Toolbox.Package

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(github_snapshot, attrs) do
    github_snapshot
    |> cast(attrs, [:data, :package_id])
    |> cast_embed(:activity)
    |> validate_required([:data, :package_id])
  end
end
