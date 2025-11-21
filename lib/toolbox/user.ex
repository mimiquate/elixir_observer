defmodule Toolbox.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Uniq.UUID, version: 7, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :github_id, :integer
    field :login, :string
    field :email, :string
    field :primary_email, :string
    field :name, :string
    field :avatar_url, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:github_id, :login, :email, :primary_email, :name, :avatar_url])
    |> validate_required([:github_id, :login])
    |> unique_constraint(:github_id)
  end
end
