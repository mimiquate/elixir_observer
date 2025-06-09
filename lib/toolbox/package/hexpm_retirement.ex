defmodule Toolbox.Package.HexpmRetirement do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :message, :string
    field :reason, :string
  end

  def changeset(retirement, attrs) do
    retirement
    |> cast(attrs, [:message, :reason])
    |> validate_required([:message, :reason])
  end
end
