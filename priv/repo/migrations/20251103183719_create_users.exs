defmodule Toolbox.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :github_id, :bigint, null: false
      add :login, :string, null: false
      add :email, :string
      add :primary_email, :string
      add :name, :string
      add :avatar_url, :string

      timestamps()
    end

    create unique_index(:users, [:github_id])
    create unique_index(:users, [:login])
  end
end
