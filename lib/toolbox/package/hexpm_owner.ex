defmodule Toolbox.Package.HexpmOwner do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :email, :string
    field :username, :string
  end

  def changeset(hexpm_owner, attrs) do
    hexpm_owner
    |> cast(attrs, [:email, :username])
  end
end
