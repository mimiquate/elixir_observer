defmodule Toolbox.PackageEmbedding do
  use Ecto.Schema
  import Ecto.Changeset

  schema "package_embeddings" do
    belongs_to :package, Toolbox.Package

    field :embedding, Pgvector.Ecto.Vector

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(package_embedding, attrs) do
    package_embedding
    |> cast(attrs, [:package_id, :embedding])
    |> validate_required([:package_id, :embedding])
    |> foreign_key_constraint(:package_id)
    |> unique_constraint(:package_id)
  end
end
