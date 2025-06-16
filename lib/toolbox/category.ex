defmodule Toolbox.Category do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field :id, :integer, primary_key: true
    field :name, :string
    field :description, :string
  end

  def changeset(category, attrs) do
    category
    |> Ecto.Changeset.cast(attrs, [:id, :name, :description])
    |> Ecto.Changeset.validate_required([:id, :name, :description])
  end
end
