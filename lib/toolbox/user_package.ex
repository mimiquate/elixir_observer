defmodule Toolbox.UserPackage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_packages" do
    belongs_to :user, Toolbox.User, type: :binary_id
    belongs_to :package, Toolbox.Package

    field :following, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(user_package, attrs) do
    user_package
    |> cast(attrs, [:user_id, :package_id, :following])
    |> validate_required([:user_id, :package_id])
    |> unique_constraint([:user_id, :package_id])
  end
end
