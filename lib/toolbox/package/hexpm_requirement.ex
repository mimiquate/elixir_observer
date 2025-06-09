defmodule Toolbox.Package.HexpmRequirement do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :name, :string
    field :requirement, :string
  end

  def changeset(requirement, attrs) do
    requirement
    |> cast(attrs, [:name, :requirement])
    |> validate_required([:name, :requirement])
  end
end
