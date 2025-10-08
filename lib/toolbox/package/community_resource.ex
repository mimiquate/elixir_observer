defmodule Toolbox.Package.CommunityResource do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :type, Ecto.Enum, values: [:video, :article, :podcast], default: :article
    field :title, :string
    field :description, :string
    field :url, :string
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:type, :title, :description, :url])
    |> validate_required(:title, :url)
  end
end
