defmodule Toolbox.Repo.Migrations.CreateApiKeys do
  use Ecto.Migration

  def change do
    create table(:api_keys) do
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :description, :text
      add :key_hash, :binary, null: false
      add :key_first_chars, :string, null: false
      add :key_last_chars, :string, null: false
      add :last_used_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:api_keys, [:user_id, :name])
    create unique_index(:api_keys, [:key_hash])
  end
end
