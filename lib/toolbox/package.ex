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

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(package, attrs) do
    package
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
  end
end
