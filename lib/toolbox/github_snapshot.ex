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
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    github_snapshot
    |> cast(attrs, [:data, :package_id])
    |> cast_embed(:activity)
    # Always update the updated_at column regardless changes
    # This is needed for packages that do not have any activity
    |> force_change(:updated_at, now)
    |> validate_required([:data, :package_id])
  end
end
