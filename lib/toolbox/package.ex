defmodule Toolbox.Package do
  use Ecto.Schema
  import Ecto.Changeset

  schema "packages" do
    field :name, :string
    field :description, :string

    has_many :hexpm_snapshots, Toolbox.HexpmSnapshot
    has_many :github_snapshots, Toolbox.GithubSnapshot

    has_one :latest_hexpm_snapshot, Toolbox.HexpmSnapshot
    has_one :latest_github_snapshot, Toolbox.GithubSnapshot

    field :hexpm_owners_sync_at, :utc_datetime
    embeds_many :hexpm_owners, Toolbox.Package.HexpmOwner, on_replace: :delete

    # Add embedded schema
    field :hexpm_latest_stable_version_data, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(package, attrs) do
    package
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
  end

  def owners_changeset(package, attrs) do
    package
    |> cast(attrs, [:hexpm_owners_sync_at])
    |> cast_embed(:hexpm_owners, required: true)
    |> validate_required([:hexpm_owners_sync_at])
  end

  def latest_stable_version_data_changeset(package, attrs) do
    package
    |> cast(attrs, [:hexpm_latest_stable_version_data])
    |> validate_required([:hexpm_latest_stable_version_data])
  end
end
