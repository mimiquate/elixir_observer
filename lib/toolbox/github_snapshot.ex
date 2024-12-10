defmodule Toolbox.GithubSnapshot do
  use Ecto.Schema
  import Ecto.Changeset

  schema "github_snapshots" do
    field :data, :map

    belongs_to :package, Toolbox.Package

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(package, attrs) do
    package
    |> cast(attrs, [:data])
    |> validate_required([:data])
  end
end
