defmodule Toolbox.Package do
  use Ecto.Schema
  import Ecto.Changeset

  schema "packages" do
    field :name, :string
    field :description, :string

    field :category, Toolbox.Category, source: :category_id

    has_many :hexpm_snapshots, Toolbox.HexpmSnapshot

    has_one :latest_hexpm_snapshot, Toolbox.HexpmSnapshot
    has_one :latest_github_snapshot, Toolbox.GithubSnapshot

    field :hexpm_owners_sync_at, :utc_datetime
    embeds_many :hexpm_owners, Toolbox.Package.HexpmOwner, on_replace: :delete

    embeds_one :hexpm_latest_stable_version_data, Toolbox.Package.HexpmVersion,
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(package, attrs) do
    package
    |> cast(attrs, [:name, :description, :category])
    |> validate_required([:name])
  end

  def category_changeset(package, attrs) do
    package
    |> cast(attrs, [:category])
    |> validate_required([:category])
  end

  def owners_changeset(package, attrs) do
    package
    |> cast(attrs, [:hexpm_owners_sync_at])
    # We found cases in hexpm that owners are empty
    # thats why is not required
    |> cast_embed(:hexpm_owners)
    |> validate_required([:hexpm_owners_sync_at])
  end

  def latest_stable_version_data_changeset(package, attrs) do
    package
    |> cast(attrs, [])
    |> cast_embed(:hexpm_latest_stable_version_data, required: true)
  end
end
