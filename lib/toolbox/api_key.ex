defmodule Toolbox.ApiKey do
  use Ecto.Schema
  import Ecto.Changeset

  schema "api_keys" do
    belongs_to :user, Toolbox.User, type: :binary_id

    field :name, :string
    field :description, :string
    field :key_hash, :binary
    field :key_first_chars, :string
    field :key_last_chars, :string
    field :last_used_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> validate_length(:name, max: 255)
    |> validate_length(:description, max: 1000)
    |> unique_constraint([:user_id, :name], error_key: :name)
  end
end
