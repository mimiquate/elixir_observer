defmodule Toolbox.Package.CommunityResource do
  defstruct [
    :title,
    :url,
    type: "article",
    description: ""
  ]

  import Ecto.Changeset

  @type t :: %__MODULE__{
          type: String.t(),
          title: String.t(),
          description: String.t() | nil,
          url: String.t()
        }

  @schema_types %{
    type: :string,
    title: :string,
    description: :string,
    url: :string
  }

  def changeset(struct, attrs) do
    {struct, @schema_types}
    |> cast(attrs, Map.keys(@schema_types))
    |> validate_required([:title, :url])
  end
end
